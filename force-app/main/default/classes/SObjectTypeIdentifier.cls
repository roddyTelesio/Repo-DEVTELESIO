public class SObjectTypeIdentifier {
    private static Map<String, String> sObjectTypeCache = new Map<String, String>();

    public static String getSObjectTypeById(Id recordId) {
        if (recordId == null || String.valueOf(recordId).length() != 18) {
            return null; // Return null if the provided Id is invalid
        }
        
        String idPrefix = String.valueOf(recordId).substring(0, 3);
        
        if (sObjectTypeCache.containsKey(idPrefix)) {
            return sObjectTypeCache.get(idPrefix);
        } else {
            // Get the SObject type from the Id
            Schema.SObjectType sObjectType = recordId.getSObjectType();
            String sObjectTypeName = sObjectType.getDescribe().getName();
            
            // Cache the SObject type based on Id prefix
            sObjectTypeCache.put(idPrefix, sObjectTypeName);
            
            return sObjectTypeName;
        }
    }
}