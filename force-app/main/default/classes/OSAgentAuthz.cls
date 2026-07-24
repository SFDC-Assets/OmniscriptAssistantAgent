public with sharing class OSAgentAuthz {

    private static final String OMNI_PROCESS_ID_KEY = '"omniProcessId":"';
    private static final String OMNISCRIPT_ID_KEY   = '"omniscriptId":"';

    public class AccessDeniedException extends Exception {}

    /**
     * Extract and authorize the OmniProcess referenced by the OmniScript JSON, and return
     * the record so callers can hand pre-resolved fields (Name, Id) to the flow directly.
     *
     * The flow no longer takes an Id input or performs a record lookup — Apex is the
     * single trust boundary. This closes the gap where a caller invoking the flow via the
     * Actions REST endpoint could supply a victim's Id as pre-authorized.
     *
     * Returns null when no Id is present in the JSON (first-turn calls before an OmniScript
     * is bound); throws AuraHandledException when an Id is present but unparseable or
     * inaccessible under WITH USER_MODE.
     */
    public static OmniProcess resolveAuthorizedOmniProcess(String osJSON) {
        if (String.isBlank(osJSON)) {
            return null;
        }
        String rawId = extractId(osJSON, OMNI_PROCESS_ID_KEY);
        if (String.isBlank(rawId)) {
            rawId = extractId(osJSON, OMNISCRIPT_ID_KEY);
        }
        if (String.isBlank(rawId)) {
            return null;
        }

        Id parsed;
        try {
            parsed = Id.valueOf(rawId);
        } catch (System.StringException e) {
            throw new AuraHandledException('Invalid OmniScript context.');
        }

        List<OmniProcess> rows = [
            SELECT Id, Name FROM OmniProcess WHERE Id = :parsed WITH USER_MODE LIMIT 1
        ];
        if (rows.isEmpty()) {
            throw new AuraHandledException('OmniScript not accessible.');
        }
        return rows[0];
    }

    /**
     * Thin wrapper for callers that only need the authorized Id.
     */
    public static Id resolveAuthorizedOmniProcessId(String osJSON) {
        OmniProcess p = resolveAuthorizedOmniProcess(osJSON);
        return p == null ? null : p.Id;
    }

    /**
     * Authorize a raw OmniProcess Id string directly (no JSON parsing). Callers that
     * already have an Id in hand (e.g. an @InvocableMethod with a typed OSId input)
     * use this to gate access before handing the Id to downstream Connect API calls
     * whose own record-level sharing enforcement is not guaranteed.
     *
     * Throws AuraHandledException when the Id is unparseable or inaccessible to the
     * calling user under WITH USER_MODE.
     */
    public static Id assertAccessibleOmniProcess(String osId) {
        if (String.isBlank(osId)) {
            throw new AuraHandledException('Missing OmniScript context.');
        }

        Id parsed;
        try {
            parsed = Id.valueOf(osId);
        } catch (System.StringException e) {
            throw new AuraHandledException('Invalid OmniScript context.');
        }

        List<OmniProcess> rows = [
            SELECT Id FROM OmniProcess WHERE Id = :parsed WITH USER_MODE LIMIT 1
        ];
        if (rows.isEmpty()) {
            throw new AuraHandledException('OmniScript not accessible.');
        }
        return parsed;
    }

    private static String extractId(String source, String key) {
        Integer keyLen = key.length();
        Integer start = source.indexOf(key);
        if (start < 0) {
            return null;
        }
        Integer valueStart = start + keyLen;
        Integer valueEnd = source.indexOf('"', valueStart);
        if (valueEnd < 0) {
            return null;
        }
        return source.substring(valueStart, valueEnd);
    }
}
