class SetAppVariables
  def initialize app
    @app = app
  end

  def call env
    begin
      # Configure griddler, mailer, cloudinary, recaptcha
      Griddler.configuration.email_service = AppSettings['email.mail_service'].present? ? AppSettings['email.mail_service'].to_sym : :sendgrid

      ActionMailer::Base.smtp_settings = {
        address:              AppSettings["email.mail_smtp"],
        port:                 AppSettings["email.mail_port"],
        user_name:            AppSettings["email.smtp_mail_username"].presence,
        password:             AppSettings["email.smtp_mail_password"].presence,
        domain:               AppSettings["email.mail_domain"],
        enable_starttls_auto: !AppSettings["email.mail_smtp"].in?(["localhost", "127.0.0.1", "::1"])
      }

      ActionMailer::Base.perform_deliveries = to_boolean(AppSettings['email.send_email'])

      Cloudinary.config do |config|
        config.cloud_name = AppSettings['cloudinary.cloud_name'].blank? ? nil : AppSettings['cloudinary.cloud_name']
        config.api_key    = AppSettings['cloudinary.api_key'].blank? ? nil : AppSettings['cloudinary.api_key']
        config.api_secret = AppSettings['cloudinary.api_secret'].blank? ? nil : AppSettings['cloudinary.api_secret']
        config.secure     = true
      end

      Recaptcha.configure do |config|
        config.public_key  = AppSettings['settings.recaptcha_site_key'].blank? ? nil : AppSettings['settings.recaptcha_site_key']
        config.private_key = AppSettings['settings.recaptcha_api_key'].blank? ? nil : AppSettings['settings.recaptcha_api_key']
        # Uncomment the following line if you are using a proxy server:
        # config.proxy = 'http://myproxy.com.au:8080'
      end

      Rails.logger.send(:info, "Application variables configured successfully.")

    rescue
      Rails.logger.send(:warn, "WARNING!!! Error setting configs.")

      if AppSettings['email.mail_service'] == 'mailin'
        AppSettings['email.mail_service'] == ''
      end
    end

    @app.call(env)
  end

  def to_boolean(str)
    str == 'true'
  end
end
