class User {
    int id;
    String name;
    String email;
    List<String> roles;
    Profile profile;

    User({
        required this.id,
        required this.name,
        required this.email,
        required this.roles,
        required this.profile,
    });

}

class Profile {
    int age;
    bool active;
    DateTime joinedAt;

    Profile({
        required this.age,
        required this.active,
        required this.joinedAt,
    });

}
