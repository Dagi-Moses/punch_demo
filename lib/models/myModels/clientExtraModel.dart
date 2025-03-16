import 'package:intl/intl.dart';

class ClientExtra {
  String? id;
  int? clientNo;
  String? politicalParty;
  String? presentPosition;
  String? hobbies;
  String? companies;

  ClientExtra({
    this.id,
    this.clientNo,
    this.politicalParty,
    this.presentPosition,
    this.hobbies,
    this.companies,
  });

  // Factory method to create a PoliticalClient object from a JSON map
  factory ClientExtra.fromJson(Map<String, dynamic> json) {
    return ClientExtra(
      id: json['_id'] as String?,
      clientNo: json['Client_No']as int?,
      politicalParty: json['Political_Party'] as String?,
      presentPosition: json['Present_Position'] as String?,
      hobbies: json['Hobbies']as String?,
      companies: json['Companies']as String?,
    );
  }

  // Method to convert a PoliticalClient object to a JSON map
  Map<String, dynamic> toJson() {
    return {
      //  '_id': id,
      'Client_No': clientNo,
      'Political_Party': politicalParty,
      'Present_Position': presentPosition,
      'Hobbies': hobbies,
      'Companies': companies,
    };
  }
}
