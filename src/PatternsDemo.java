public class PatternsDemo {
    // 1. Singleton: один экземпляр конфигурации приложения.
    public static final class AppConfig {
        private static final AppConfig INSTANCE = new AppConfig();
        private final String currency = "RUB";

        private AppConfig() { }

        public static AppConfig getInstance() {
            return INSTANCE;
        }

        public String getCurrency() {
            return currency;
        }
    }

    // 2. Factory Method: создание нужного способа уведомления.
    public interface Notification {
        String send(String recipient);
    }

    public static final class EmailNotification implements Notification {
        @Override
        public String send(String recipient) {
            return "Email sent to " + recipient;
        }
    }

    public static final class SmsNotification implements Notification {
        @Override
        public String send(String recipient) {
            return "SMS sent to " + recipient;
        }
    }

    public abstract static class NotificationFactory {
        public abstract Notification create();

        public String notifyUser(String recipient) {
            return create().send(recipient);
        }
    }

    public static final class EmailFactory extends NotificationFactory {
        @Override
        public Notification create() {
            return new EmailNotification();
        }
    }

    public static final class SmsFactory extends NotificationFactory {
        @Override
        public Notification create() {
            return new SmsNotification();
        }
    }

    // 3. Builder: пошаговая сборка заказа с проверкой количества.
    public static final class Order {
        private final String product;
        private final int quantity;
        private final boolean express;

        private Order(Builder builder) {
            this.product = builder.product;
            this.quantity = builder.quantity;
            this.express = builder.express;
        }

        public String summary() {
            return product + ", quantity=" + quantity + ", express=" + express;
        }

        public static final class Builder {
            private final String product;
            private int quantity = 1;
            private boolean express;

            public Builder(String product) {
                if (product == null || product.trim().isEmpty()) {
                    throw new IllegalArgumentException("Product name is required");
                }
                this.product = product;
            }

            public Builder quantity(int value) {
                if (value <= 0) {
                    throw new IllegalArgumentException("Quantity must be positive");
                }
                this.quantity = value;
                return this;
            }

            public Builder express(boolean value) {
                this.express = value;
                return this;
            }

            public Order build() {
                return new Order(this);
            }
        }
    }

    public static void main(String[] args) {
        AppConfig config = AppConfig.getInstance();
        System.out.println("Singleton: currency=" + config.getCurrency());
        NotificationFactory email = new EmailFactory();
        NotificationFactory sms = new SmsFactory();
        System.out.println("Factory Method: " + email.notifyUser("simran@example.test"));
        System.out.println("Factory Method: " + sms.notifyUser("+70000000000"));
        Order order = new Order.Builder("Notebook").quantity(2).express(true).build();
        System.out.println("Builder: " + order.summary());
    }
}
