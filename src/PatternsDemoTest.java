public class PatternsDemoTest {
    private static void check(boolean condition, String message) {
        if (!condition) {
            throw new AssertionError(message);
        }
    }

    public static void main(String[] args) {
        check(PatternsDemo.AppConfig.getInstance() == PatternsDemo.AppConfig.getInstance(),
                "Singleton must return the same object");
        check("RUB".equals(PatternsDemo.AppConfig.getInstance().getCurrency()),
                "Currency should be RUB");

        PatternsDemo.NotificationFactory email = new PatternsDemo.EmailFactory();
        PatternsDemo.NotificationFactory sms = new PatternsDemo.SmsFactory();
        check(email.create() instanceof PatternsDemo.EmailNotification,
                "Email factory should produce EmailNotification");
        check(sms.create() instanceof PatternsDemo.SmsNotification,
                "SMS factory should produce SmsNotification");
        check(email.notifyUser("test@example.test").contains("Email sent"),
                "Email notification must work");

        PatternsDemo.Order order = new PatternsDemo.Order.Builder("Mouse")
                .quantity(3).express(false).build();
        check(order.summary().contains("quantity=3"),
                "Builder should preserve quantity");

        boolean rejected = false;
        try {
            new PatternsDemo.Order.Builder("Mouse").quantity(0);
        } catch (IllegalArgumentException ex) {
            rejected = true;
        }
        check(rejected, "Builder should reject invalid quantities");
        System.out.println("All KT3 tests passed");
    }
}
