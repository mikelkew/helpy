class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  helper_method :recaptcha_enabled?

  before_action :add_root_breadcrumb
  before_action :set_locale
  before_action :configure_permitted_parameters, if: :devise_controller?
  around_action :set_time_zone, if: :current_user

  force_ssl if: :ssl_configured?

  def url_options
    { locale: I18n.locale, theme: params[:theme] }.merge(super)
  end

  def after_sign_in_path_for(_resource)
    # If the user is an agent, redirect to admin panel
    redirect_url = current_user.is_agent? ? admin_root_url : root_url
    oauth_url = current_user.is_agent? ? admin_root_url : request.env['omniauth.origin']
    oauth_url || redirect_url
  end

  def recaptcha_enabled?
    AppSettings['settings.recaptcha_enabled'] == '1' && AppSettings['settings.recaptcha_site_key'].present? && AppSettings['settings.recaptcha_api_key'].present?
  end

  def cloudinary_enabled?
    AppSettings['cloudinary.enabled'] == '1' && AppSettings['cloudinary.cloud_name'].present? && AppSettings['cloudinary.api_key'].present? && AppSettings['cloudinary.api_secret'].present?
  end
  helper_method :cloudinary_enabled?

  def tracker(ga_category, ga_action, ga_label, ga_value=nil)
    if AppSettings['settings.google_analytics_id'].present? && cookies['_ga'].present?
      ga_cookie = cookies['_ga'].split('.')
      ga_client_id = ga_cookie[2] + '.' + ga_cookie[3]
      logger.info("Enqueing job for #{ga_client_id}")

      TrackerJob.perform_later(
        ga_category,
        ga_action,
        ga_label,
        ga_value,
        ga_client_id,
        AppSettings['settings.google_analytics_id']
      )
    end
  end

  def ssl_configured?
    AppSettings["settings.enforce_ssl"] == '1' && Rails.env.production?
  end

  def google_analytics_enabled?
    AppSettings['settings.google_analytics_enabled'] == '1'
  end
  helper_method :google_analytics_enabled?

  def rtl_locale?(locale)
    return true if %w(ar dv he iw fa nqo ps sd ug ur yi).include?(locale)
    return false
  end
  helper_method :rtl_locale?

  def welcome_email?
    AppSettings['settings.welcome_email'] == "1" || AppSettings['settings.welcome_email'] == true
  end
  helper_method :welcome_email?

  def forums?
    AppSettings['settings.forums'] == "1" || AppSettings['settings.forums'] == true
  end
  helper_method :forums?

  def hide_admin_footer?
    AppSettings['settings.hide_admin_footer'] == "1" || AppSettings['settings.hide_admin_footer'] == true
  end
  helper_method :hide_admin_footer?

  def hide_app_footer?
    AppSettings['settings.hide_app_footer'] == "1" || AppSettings['settings.hide_app_footer'] == true
  end
  helper_method :hide_app_footer?

  def knowledgebase?
    AppSettings['settings.knowledgebase'] == "1" || AppSettings['settings.knowledgebase'] == true
  end
  helper_method :knowledgebase?

  def tickets?
    AppSettings['settings.tickets'] == "1" || AppSettings['settings.tickets'] == true
  end
  helper_method :tickets?

  def teams?
    true
  end
  helper_method :teams?

  def display_branding?
    AppSettings['branding.display_branding'] == "1" || AppSettings['branding.display_branding'] == true
  end
  helper_method :display_branding?

  def forums_enabled?
    raise ActionController::RoutingError.new('Not Found') unless forums?
  end

  def knowledgebase_enabled?
    raise ActionController::RoutingError.new('Not Found') unless knowledgebase?
  end

  def tickets_enabled?
    raise ActionController::RoutingError.new('Not Found') unless tickets?
  end

  def topic_creation_enabled?
    raise ActionController::RoutingError.new('Not Found') unless tickets? || forums?
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:accept_invitation).concat [:name]
  end

  private

  def add_root_breadcrumb
    if controller_namespace_origin == 'admin'
      add_breadcrumb :root, admin_root_url
    else
      add_breadcrumb :root
    end
  end

  def controller_namespace_origin
    controller_path.split('/').first
  end

  def set_locale
    @browser_locale = http_accept_language.compatible_language_from(AppSettings['i18n.available_locales'])
    unless params[:locale].blank?
      I18n.locale = AppSettings['i18n.available_locales'].include?(params[:locale]) ? params[:locale] : AppSettings['i18n.default_locale']
    else
      I18n.locale = @browser_locale
    end
  end

  def to_boolean(str)
    str == 'true'
  end

  def allow_iframe_requests
    response.headers.delete('X-Frame-Options')
  end

  def theme_chosen
    if params[:theme].present?
      params[:theme]
    else
      AppSettings['theme.active'].present? ? AppSettings['theme.active'] : 'helpy'
    end
  end

  def set_time_zone(&block)
    Time.use_zone(current_user.time_zone, &block)
  end

  def get_all_teams
    return unless teams?
    @all_teams = ActsAsTaggableOn::Tagging.includes(:tag).where(context: 'teams').uniq.pluck(:name).map{|name| name}
  end

end
