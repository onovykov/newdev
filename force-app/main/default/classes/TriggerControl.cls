public class TriggerControl {

    private static Set<String> disabledHandlers = new Set<String>();

    // ===== Disable =====
    public static void disable(String handlerName) {
        if (String.isNotBlank(handlerName)) {
            disabledHandlers.add(handlerName);
        }
    }

    public static void disable(Type handlerType) {
        if (handlerType != null) {
            disable(handlerType.getName());
        }
    }

    // ===== Enable =====
    public static void enable(String handlerName) {
        if (String.isNotBlank(handlerName)) {
            disabledHandlers.remove(handlerName);
        }
    }

    public static void enable(Type handlerType) {
        if (handlerType != null) {
            enable(handlerType.getName());
        }
    }

    // ===== Check =====
    public static Boolean isDisabled(String handlerName) {
        return handlerName != null && disabledHandlers.contains(handlerName);
    }

    public static Boolean isDisabled(Type handlerType) {
        return handlerType != null && isDisabled(handlerType.getName());
    }

    // ===== Reset (important for tests) =====
    public static void reset() {
        disabledHandlers.clear();
    }

    // ===== Debug helper (optional) =====
    public static Set<String> getDisabledHandlers() {
        return new Set<String>(disabledHandlers);
    }
}
