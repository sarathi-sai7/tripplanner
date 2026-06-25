class Memory {
  String title;
  String location;
  String imagePath;

  Memory({required this.title, required this.location, required this.imagePath});

  Map<String, dynamic> toJson() => {
        'title': title,
        'location': location,
        'imagePath': imagePath,
      };

  factory Memory.fromJson(Map<String, dynamic> json) => Memory(
        title: json['title'],
        location: json['location'],
        imagePath: json['imagePath'],
      );
}

class Album {
  String name;
  List<Memory> memories;

  Album({required this.name, required this.memories});

  Map<String, dynamic> toJson() => {
        'name': name,
        'memories': memories.map((m) => m.toJson()).toList(),
      };

  factory Album.fromJson(Map<String, dynamic> json) => Album(
        name: json['name'],
        memories: (json['memories'] as List)
            .map((m) => Memory.fromJson(m))
            .toList(),
      );

  Album copyWith({String? name, List<Memory>? memories}) => Album(
        name: name ?? this.name,
        memories: memories ?? this.memories,
      );
}
