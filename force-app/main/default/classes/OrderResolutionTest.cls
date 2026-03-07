@IsTest
private class OrderResolutionTest {

    private static Order createOrder() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Order ord = new Order(
            AccountId     = acc.Id,
            Status        = 'Draft',
            EffectiveDate = Date.today()
        );
        insert ord;

        return ord;
    }

    @IsTest
    static void test_found_resolution() {

        Order ord = createOrder();

        OrderResolution res = OrderResolution.found(ord);

        // базовий клас
        System.assertEquals(true, res.found);
        System.assertEquals(null, res.reason);

        // конкретний клас
        System.assertNotEquals(null, res.order);
        System.assertEquals(ord.Id, res.order.Id);
    }

    @IsTest
    static void test_not_found_resolution() {

        String reason = 'Order not found';

        OrderResolution res =
            OrderResolution.notFound(reason);

        System.assertEquals(false, res.found);
        System.assertEquals(reason, res.reason);
        System.assertEquals(null, res.order);
    }

    @IsTest
    static void test_polymorphic_access() {

        IntegrationResolution base =
            OrderResolution.notFound('X');

        System.assertEquals(false, base.found);
        System.assertEquals('X', base.reason);
    }
}