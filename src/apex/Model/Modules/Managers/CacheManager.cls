public class CacheManager {

	private static final String CACHE_MAP_NAME = 'CacheSettings';
	private static final String CACHE_INDEX_KEY = 'CacheIndex';
	private static final String CACHE_START_INDEX = '00000000';

	private static Integer cacheIndex;

	public static Boolean cache(String mapName, Map<String, String> data) {
		if (mapName == null || data == null || data.size() == 0) return false;
		init();
		List<Cache__c> toInsert = new List<Cache__c>();
		for (String key : data.keySet()) {
			toInsert.add(new Cache__c(Name = indexAsString(++cacheIndex), MapName__c = mapName, Key__c = key, Value__c = data.get(key)));
		}
		SavePoint save = Database.setSavepoint();
		try {
			insert toInsert;
			setCacheIndex(cacheIndex);
			return true;
		} catch (Exception ex) {
			Database.rollback(save);
			return false;
		}
	}

	public static Map<String, String> getMap(String mapName) {
		Map<String, String> result = new Map<String, String>();
		for (Cache__c item : Cache__c.getAll().values()) {
			if (item.MapName__c == mapName) {
				result.put(item.Key__c, item.Value__c);
			}
		}
		return result;
	}

	public static Map<String, String> getMap(String mapName, Set<String> keys) {
		Map<String, String> result = new Map<String, String>();
		if (keys == null) return result;
		for (Cache__c item : Cache__c.getAll().values()) {
			if (item.MapName__c == mapName && keys.contains(item.Key__c)) {
				result.put(item.Key__c, item.Value__c);
			}
		}
		return result;
	}

	public static void release(String mapName) {
		List<Cache__c> toDelete = new List<Cache__c>();
		for (Cache__c item : Cache__c.getAll().values()) {
			if (item.MapName__c == mapName) {
				toDelete.add(item);
			}
		}
		delete toDelete;
	}

	public static void release(String mapName, Set<String> keys) {
		List<Cache__c> toDelete = new List<Cache__c>();
		if (keys == null) return;
		for (Cache__c item : Cache__c.getAll().values()) {
			if (item.MapName__c == mapName && keys.contains(item.Key__c)) {
				toDelete.add(item);
			}
		}
		delete toDelete;
	}

	public static Set<String> getMapNames() {
		Set<String> result = new Set<String>();
		for (Cache__c item : Cache__c.getAll().values()) {
			result.add(item.MapName__c);
		}
		return result;
	}

	private static void init() {
		Integer lastCacheIndex;
		try {
			lastCacheIndex = Integer.valueOf(Cache__c.getInstance(CACHE_START_INDEX).Value__c);
		} catch (Exception ex) {
			lastCacheIndex = 0;
			List<Cache__c> toUpdate = new List<Cache__c>();
			for (Cache__c cache : Cache__c.getAll().values()) {
				cache.Name = indexAsString(++lastCacheIndex);
				toUpdate.add(cache);
			}
			if (toUpdate.size() > 0) update toUpdate;
			insert new Cache__c(Name = CACHE_START_INDEX, MapName__c = CACHE_MAP_NAME, Key__c = CACHE_INDEX_KEY, Value__c = String.valueOf(lastCacheIndex));
		}
		cacheIndex = lastCacheIndex;
	}

	private static void setCacheIndex(Integer index) {
		Cache__c cacheItem = Cache__c.getInstance('00000000');
		cacheItem.Value__c = String.valueOf(index);
		update cacheItem;
		cacheIndex = null;
	}

	private static String indexAsString(Integer index) {
		String stringIndex = '0000000000' + String.valueOf(index);
		return stringIndex.substring(stringIndex.length() - 8, stringIndex.length());
	}

}