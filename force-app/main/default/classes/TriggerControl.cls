public class TriggerControl {

    private static Set<String> disabledHandlers = new Set<String>();

    public static void disable(String handlerName) {
        disabledHandlers.add(handlerName);
    }

    public static void enable(String handlerName) {
        disabledHandlers.remove(handlerName);
    }

    public static Boolean isDisabled(String handlerName) {
        return disabledHandlers.contains(handlerName);
    }

    public static void reset() {
        disabledHandlers.clear();
    }

    public static void disable(Type handlerType) {
        disable(String.valueOf(handlerType));
    }

    public static void enable(Type handlerType) {
        enable(String.valueOf(handlerType));
    }

    public static Boolean isDisabled(Type handlerType) {
        return isDisabled(String.valueOf(handlerType));
    }    
}