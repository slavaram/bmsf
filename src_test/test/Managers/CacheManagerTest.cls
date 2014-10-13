@isTest
class CacheManagerTest {

	static testmethod void test() {
		Map<String, String> mapToCache = new Map<String, String>();
		mapToCache.put('Key1', 'Value1');
		mapToCache.put('Key2', 'Value2');
		mapToCache.put('Key3', 'Value3');
		System.assertEquals(true, CacheManager.cache('TestMap', mapToCache));
		System.assertEquals(3, CacheManager.getMap('TestMap').size());
		System.assertEquals('Value2', CacheManager.getMap('TestMap', new Set<String> {'Key2'}).get('Key2'));
		CacheManager.release('TestMap', new Set<String> {'Key2'});
		System.assertEquals(0, CacheManager.getMap('TestMap', new Set<String> {'Key2'}).size());
		CacheManager.release('TestMap');
		System.assertEquals(0, CacheManager.getMap('TestMap').size());
		System.assertNotEquals(null, CacheManager.getMapNames());
	}

}