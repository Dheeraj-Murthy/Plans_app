class Project {
  final String id;
  final String name;
  final int colorIndex;

  const Project({
    required this.id,
    required this.name,
    this.colorIndex = 0,
  });

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'] as String,
      name: map['name'] as String,
      colorIndex: map['color_index'] as int,
    );
  }

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
