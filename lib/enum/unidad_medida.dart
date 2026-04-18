enum UnidadMedida {
  METRO_LINEAL,
  METRO_CUADRADO,
  METRO_CUBICO,
  KILOGRAMO,
  BULTO,
  LITRO,
  GALON,
  UNIDAD,
  GLOBAL,
}

extension UnidadMedidaExt on UnidadMedida {
  String get nombre {
    switch (this) {
      case UnidadMedida.METRO_LINEAL:
        return "Metro Lineal (ML)";
      case UnidadMedida.METRO_CUADRADO:
        return "Metro Cuadrado (M2)";
      case UnidadMedida.METRO_CUBICO:
        return "Metro Cúbico (M3)";
      case UnidadMedida.KILOGRAMO:
        return "Kilogramo (KG)";
      case UnidadMedida.BULTO:
        return "Bulto (BLT)";
      case UnidadMedida.LITRO:
        return "Litro (L)";
      case UnidadMedida.GALON:
        return "Galón (GL)";
      case UnidadMedida.UNIDAD:
        return "Unidad (UND)";
      case UnidadMedida.GLOBAL:
        return "Global (GLB)";
    }
  }
}
