class GroupsController < ApplicationController
  before_filter :get_current_user
  before_filter :get_group, :except => [:index, :new, :create]
  before_filter :check_group_owner, :only => [:edit, :update, :destroy]

  include GraphFunctions
  
  def index
    @subsections, @groups =  Group.browse(params[:string])
  end
 
  def show
    respond_to do |format|
      format.html {
        @comments = @group.comments
        # Generate league table
        @leaguetable = []
        @group.users.each { |u| @leaguetable << { :user => u, :total => (u.annual_emissions > 0 and u.public) ? u.annual_emissions : 9e99 } }
        @leaguetable = @leaguetable.sort{ |x,y| x[:total] <=> y[:total] }
        # Generate pie chart URL
        @pie_url = group_path(@group, :format => :xmlchart)
      }
      format.xmlchart {
        srand(69)
        # Store totals
        @totals = []
        @colours = []
        total = 0.0
        @group.users.each { |u| total += u.annual_emissions if u.public }
        # For each account, calculate emissions
        @group.users.each do |user|
          # Create totals
          @totals << {:name => user.name, :data => { :total => user.annual_emissions, :percentage => user.annual_emissions/total} } if user.public
          # Create colours
          @colours << random_colour
        end
        # Send data
        render :file => 'shared/pie', :layout => false
      }
      format.atom {
        @comments = @group.comments.find(:all, :order => "created_at DESC", :limit => 10)
      }
    end
  end

  def new
    @group = Group.new
  end

  def create
    @group = Group.create(params[:group])
    if @group.save
      redirect_to @group
    else
      render :action => "new"
    end
  end

  def edit
    if request.post?      
      if verify_recaptcha(@group)
        @group.update_attributes(params[:group])
        if @group.owner.nil?
         @group.owner = @current_user
        end
        redirect_to :action => 'view', :id => @group if @group.save
      end
    end
    # Set page name
    if params[:id]
      @pagename = "Editing " + @group.name
    else
      @pagename = "Create a new group"
    end
  end

  def update
    @group.update_attributes(params[:group])
    if @group.save
      redirect_to @group
    else
      render :action => "edit"
    end
  end

  def destroy
    @group.destroy
    redirect_to groups_path
  end

  def invite
    @group = @current_user.groups.find(params[:id]) 
    @friends = Array.new(@current_user.friends)
    @group.users.each do |user|
      @friends.delete(user) 
    end
  rescue
    flash[:notice] = "Unknown group!"    
    redirect_to :action => 'list'
  end

  def send_invitations
    group = @current_user.groups.find(params[:id]) 
    @current_user.friends.each do |friend|
      if params[:invite][friend.login] == "1"
        # Create invitation - automatically notifies the invited person
        GroupInvitation.create(:user => friend, :inviter => @current_user, :group => group)
      end
    end
    flash[:notice] = "Invitations sent!"
    redirect_to :action => 'view', :id => params[:id]
  rescue
    flash[:notice] = "Unknown group!"
    redirect_to :action => 'list'
  end

  def invite_accept
    invitation = @current_user.group_invitations.find(params[:id])
    invitation.accept
    redirect_to :action => 'list'
  rescue
    flash[:notice] = "Unknown invitation ID!"
    redirect_to :action => 'list'
  end
  
  def invite_reject
    invitation = @current_user.group_invitations.find(params[:id])
    invitation.reject
    redirect_to :action => 'list'
  rescue
    flash[:notice] = "Unknown invitation ID!"
    redirect_to :action => 'list'
  end

  protected

  def get_group
    @group = Group.find_by_name(params[:id])
  end

  def check_group_owner
    raise AccessDenied unless @current_user.admin? || @current_user == @group.owner
  end

end
