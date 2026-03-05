public class IntegrationDummyHandler implements IIntegrationHandler {
    //--- Dummy-клас для тесту Integration Orchestrator-a
    //    Після тестування й успішного релізу - видалити
    //    НА ПРОД НЕ ДЕПЛОЇТИ
    public void handle(IntegrationContext ctx) {
        ctx.putResult('dummy', 'ok');
    }
}