public class ContentVersionSorter {
    public static List<ContentVersion> sortByPhase(List<ContentVersion> contentVersions) {
        contentVersions.sort(new PhaseComparator());
        return contentVersions;
    }
    
    private class PhaseComparator implements Comparator<ContentVersion> {
        public Integer compare(ContentVersion cv1, ContentVersion cv2) {

            System.debug('sortPhase cv1' + cv1);
            System.debug('sortPhase cv2' + cv2);
            if (cv1.TECH_PhaseNumber__c == cv2.TECH_PhaseNumber__c) {
                return 0;
            } else if (cv1.TECH_PhaseNumber__c < cv2.TECH_PhaseNumber__c) {
                return -1;
            } else {
                return 1;
            }
        }
    }
}