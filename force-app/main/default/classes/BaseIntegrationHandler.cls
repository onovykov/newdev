public abstract class BaseIntegrationHandler implements IIntegrationHandler {

    public void handle(IntegrationContext ctx) {

        try {
            before(ctx);

            Object dto = parse(ctx);
            ctx.parsedMessage = dto;

            validate(ctx, dto);

            if (ctx.stopProcessing) return;

            process(ctx, dto);

            if (ctx.stopProcessing) return;

            after(ctx);

        } catch (IntegrationDomainException ex) {

            ctx.addError(
                ex.handlerName + ':' + ex.code + ':' + ex.contextValue
            );

        } catch (Exception ex) {

            ctx.addError(
                'UNEXPECTED:' + ex.getMessage()
            );
        }
    }

    protected virtual void before(IntegrationContext ctx) {}

    protected abstract Object parse(IntegrationContext ctx);

    protected virtual void validate(IntegrationContext ctx, Object dto) {}

    protected abstract void process(IntegrationContext ctx, Object dto);

    protected virtual void after(IntegrationContext ctx) {}
}