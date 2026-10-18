class TrustedContact {
  const TrustedContact({
    required this.name,
    required this.phone,
    required this.relation,
    this.uid,
    this.hasApp = false,
  });

  final String name;
  final String phone;
  final String relation;
  final String? uid;
  final bool hasApp;

  Map<String, dynamic> toMap() => {
        'name': name,
        'phone': phone,
        'relation': relation,
        if (uid != null) 'uid': uid,
        'hasApp': hasApp,
      };

  factory TrustedContact.fromMap(Map<String, dynamic> map) {
    return TrustedContact(
      name: map['name']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      relation: map['relation']?.toString() ?? 'Friend',
      uid: map['uid']?.toString(),
      hasApp: map['hasApp'] == true || map['uid'] != null,
    );
  }
}
