class Project {
  final String id;
  final String name;
  final int colorIndex;

  const Project({
    required this.id,
    required this.name,
    this.colorIndex = 0,
  });

  Project copyWith({
    String? id,
    String? name,
    int? colorIndex,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      colorIndex: colorIndex ?? this.colorIndex,
    );
  }
}
