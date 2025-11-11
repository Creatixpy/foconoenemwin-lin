enum TemaTipo {
  sugerido,
  personalizado,
  ia;

  static TemaTipo fromName(String value) {
    return TemaTipo.values.firstWhere(
      (element) => element.name == value,
      orElse: () => TemaTipo.sugerido,
    );
  }
}
