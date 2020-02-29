import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:auto_route_generator/utils.dart';
import 'package:build/build.dart';

// holds constructor parameter info to be used
// in generating route parameters.
class RouteParamConfig {
  String type;
  String name;
  bool isPositional;
  bool isRequired;
  String defaultValueCode;
  Set<String> imports = {};
}

class RouteParamterResolver {
  final Resolver _resolver;
  final Set<String> imports = {};

  RouteParamterResolver(this._resolver);

  Future<RouteParamConfig> resolve(ParameterElement parameterElement) async {
    final paramConfig = RouteParamConfig();
    final paramType = parameterElement.type;
    paramConfig.type = paramType.getDisplayString();
    paramConfig.name = parameterElement.name;
    paramConfig.isPositional = parameterElement.isPositional;
    paramConfig.defaultValueCode = parameterElement.defaultValueCode;
    paramConfig.isRequired = parameterElement.hasRequired;

    // import type
    await _addImport(paramType.element);

    // import generic types recursively
    await _checkForParameterizedTypes(paramType);

    paramConfig.imports = imports;
    return paramConfig;
  }

  Future<void> _checkForParameterizedTypes(DartType paramType) async {
    if (paramType is ParameterizedType) {
      paramType.typeArguments.forEach((type) async {
        await _checkForParameterizedTypes(type);
        if (type.element.source != null) {
          await _addImport(type.element);
        }
      });
    }
  }

  Future<void> _addImport(Element element) async {
    final import = await _resolveLibImport(element);
    if (import != null) {
      imports.add(import);
    }
  }

  Future<String> _resolveLibImport(Element element) async {
    if (element.source == null || element.source.isInSystemLibrary) {
      return null;
    }
    final assetId = await _resolver.assetIdForElement(element);
    final lib = await _resolver.findLibraryByName(assetId.package);
    if (lib != null) {
      return getImport(lib);
    } else {
      return getImport(element);
    }
  }
}
