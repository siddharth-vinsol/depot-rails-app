class ApplicationController < ActionController::Base
  before_action :authorize

  protected def authorize
    unless current_user
      redirect_to login_url, alert: "Please log in before proceeding."
    end
  end

  protected def current_user
    @logged_in_user ||= User.find_by(id: session[:user_id])
  end

  protected def authorize_admin
    unless current_user.admin?
      redirect_to store_index_path, notice: "You don't have privilege to access this section"
    end
  end
end
