public class TriggerControlScope {

    private Set<String> handlers = new Set<String>();

    public TriggerControlScope(Type handlerType) {
        String key = String.valueOf(handlerType);
        handlers.add(key);
        TriggerControl.disable(handlerType);
    }

    public TriggerControlScope(Set<Type> handlerTypes) {
        for (Type t : handlerTypes) {
            String key = String.valueOf(t);
            handlers.add(key);
            TriggerControl.disable(t);
        }
    }

    public void dispose() {
        for (String h : handlers) {
            TriggerControl.enable(h);
        }
    }
}