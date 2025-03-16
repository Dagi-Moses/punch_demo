

class Const {
 

  static const String serverUrl = String.fromEnvironment(
    'SERVER_URL',
    defaultValue: 'http://localhost:3000', 
  );

  //  static const String serverUrl =  'http://localhost:3000';
   static const String userUrl = '$serverUrl/users';
   static const String userRecordUrl = '$serverUrl/userRecords';
   static const String validateTokenUrl = '$serverUrl/validateToken';
   static const String authUrl = '$serverUrl/login';
   static const String anniversaryUrl = '$serverUrl/anniversaries';
   static const String anniversaryTypeUrl = '$serverUrl/anniversaryTypes';
   static const String anniversarySectorUrl = '$serverUrl/anniversarySectors';
   static const String paperUrl = '$serverUrl/papers';
   static const String clientExtraUrl = '$serverUrl/clientExtras';
   static const String clientUrl = '$serverUrl/clients';
   static const String titleUrl = '$serverUrl/titles';
   static const String companyUrl = '$serverUrl/companies';
   static const String companyExtraUrl = '$serverUrl//companyExtras';
   static const String companySectorUrl = '$serverUrl/companySectors';


//WEBSOCKET
  static const String webSocketUrl = String.fromEnvironment(
    'WEBSOCKET_URL',
    defaultValue: 'ws://localhost:3000?channel=', // Default for local dev
  );
 
    static const String anniversaryChannel = '${webSocketUrl}anniversary'; 
    static const String authChannel = '${webSocketUrl}auth'; 
    static const String userRecordChannel = '${webSocketUrl}userRecord'; 
    static const String clientExtraChannel = '${webSocketUrl}clientExtra'; 
    static const String clientChannel = '${webSocketUrl}client'; 
    static const String companyChannel = '${webSocketUrl}company'; 
    static const String companyExtraChannel = '${webSocketUrl}companyExtra'; 


}