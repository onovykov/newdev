public class IteNumberExtractor {
    public static Set<String> extract(String jsonStr){
        Set<String> out = new Set<String>();
        Map<String,Object> root = (Map<String,Object>) JSON.deserializeUntyped(jsonStr);
        if(root == null) return out;

        Map<String,Object> data = (Map<String,Object>) root.get('Data');
        if(data == null) return out;

        List<Object> items = (List<Object>) data.get('Items');
        if(items == null) return out;

        for(Object o : items){
            Map<String,Object> m = (Map<String,Object>) o;
            Object v = m.get('IteNumber'); // ключ у JSON саме "IteNumber"
            if(v != null) out.add(String.valueOf(v));
        }
        return out;
    }
}