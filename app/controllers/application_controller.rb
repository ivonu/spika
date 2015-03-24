class ApplicationController < ActionController::Base

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  include Pundit
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  before_action :configure_permitted_parameters_for_devise, if: :devise_controller?

  before_filter :load_links

  def load_links
    @links = Link.all()
  end

  def index
    @entries = Entry.last(5).reverse
    @news = News.paginate(:page => params[:page], :per_page => 3).order('id DESC')
  end

  def about

  end

  def theory

  end

  def new_idea

  end

  protected
  def configure_permitted_parameters_for_devise
    devise_parameter_sanitizer.for(:sign_up) << :name
    devise_parameter_sanitizer.for(:account_update) << :name
  end

  private
    def user_not_authorized
      flash[:alert] = 'You are not authorized to perform this action.'
      redirect_to(request.referrer || root_path)
    end
end
