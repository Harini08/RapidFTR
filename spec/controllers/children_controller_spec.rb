require 'spec_helper'

def inject_export_generator( fake_export_generator, child_data )
	allow(ExportGenerator).to receive(:new).with(child_data).and_return( fake_export_generator )
end

def stub_out_export_generator child_data = []
	inject_export_generator( stub_export_generator = double(ExportGenerator) , child_data)
	allow(stub_export_generator).to receive(:child_photos).and_return('')
	stub_export_generator
end

def stub_out_child_get(mock_child = double(Child))
	allow(Child).to receive(:get).and_return( mock_child )
	mock_child
end

describe ChildrenController, :type => :controller do

  before :each do
    fake_admin_login
  end

  def mock_child(stubs={})
    @mock_child ||= mock_model(Child, stubs).as_null_object
  end

  it 'GET reindex' do
    expect(Child).to receive(:reindex!).and_return(nil)
    get :reindex
    expect(response).to be_success
  end

  describe '#authorizations' do
    describe 'collection' do
      it "GET index" do
        expect(@controller.current_ability).to receive(:can?).with(:index, Child).and_return(false);
        get :index
        expect(response.status).to eq(403)
      end

      it "GET search" do
        expect(@controller.current_ability).to receive(:can?).with(:index, Child).and_return(false);
        get :search
        expect(response.status).to eq(403)
      end

      it "GET new" do
        expect(@controller.current_ability).to receive(:can?).with(:create, Child).and_return(false);
        get :new
        expect(response.status).to eq(403)
      end

      it "POST create" do
        expect(@controller.current_ability).to receive(:can?).with(:create, Child).and_return(false);
        post :create
        expect(response.status).to eq(403)
      end

    end

    describe 'member' do
      before :each do
        allow(User).to receive(:find_by_user_name).with("uname").and_return(user = double('user', :user_name => 'uname', :organisation => 'org'))
        @child = Child.create('last_known_location' => "London", :short_id => 'short_id', :created_by => "uname")
        @child_arg = hash_including("_id" => @child.id)
      end

      it "GET show" do
        expect(@controller.current_ability).to receive(:can?).with(:read, @child_arg).and_return(false);
         get :show, :id => @child.id
         expect(response.status).to eq(403)
      end

      it "PUT update" do
        expect(@controller.current_ability).to receive(:can?).with(:update, @child_arg).and_return(false);
        put :update, :id => @child.id
        expect(response.status).to eq(403)
      end

      it "PUT edit_photo" do
        expect(@controller.current_ability).to receive(:can?).with(:update, @child_arg).and_return(false);
        put :edit_photo, :id => @child.id
        expect(response.status).to eq(403)
      end

      it "PUT update_photo" do
        expect(@controller.current_ability).to receive(:can?).with(:update, @child_arg).and_return(false);
        put :update_photo, :id => @child.id
        expect(response.status).to eq(403)
      end

      it "PUT select_primary_photo" do
        expect(@controller.current_ability).to receive(:can?).with(:update, @child_arg).and_return(false);
        put :select_primary_photo, :child_id => @child.id, :photo_id => 0
        expect(response.status).to eq(403)
      end

      it "DELETE destroy" do
        expect(@controller.current_ability).to receive(:can?).with(:destroy, @child_arg).and_return(false);
        delete :destroy, :id => @child.id
        expect(response.status).to eq(403)
      end
    end
  end

  describe "GET index" do

    shared_examples_for "viewing children by user with access to all data" do
      describe "when the signed in user has access all data" do
        before do
          fake_field_admin_login
          @options ||= {}
          @stubs ||= {}
        end

        it "should assign all childrens as @childrens" do
          page = @options.delete(:page)
          per_page = @options.delete(:per_page)
          children = [mock_child(@stubs)]
          @status ||= "all"
          allow(children).to receive(:paginate).and_return(children)
          expect(Child).to receive(:fetch_paginated).with(@options, page, per_page).and_return([1, children])

          get :index, :status => @status
          expect(assigns[:children]).to eq(children)
        end
      end
    end

    shared_examples_for "viewing children as a field worker" do
      describe "when the signed in user is a field worker" do
        before do
          @session = fake_field_worker_login
          @stubs ||= {}
          @options ||= {}
          @params ||= {}
        end

        it "should assign the children created by the user as @childrens" do
          children = [mock_child(@stubs)]
          page = @options.delete(:page)
          per_page = @options.delete(:per_page)
          @status ||= "all"
          allow(children).to receive(:paginate).and_return(children)
          expect(Child).to receive(:fetch_paginated).with(@options, page, per_page).and_return([1, children])
          @params.merge!(:status => @status)
          get :index, @params
          expect(assigns[:children]).to eq(children)
        end
      end
    end

    context "viewing all children" do
      before { @stubs = { :reunited? => false } }
      context "when status is passed for admin" do
        before { @status = "all"}
        before {@options = {:startkey=>["all"], :endkey=>["all", {}], :page=>1, :per_page=>20, :view_name=>:by_all_view_name}}
        it_should_behave_like "viewing children by user with access to all data"
      end

      context "when status is passed for field worker" do
        before { @status = "all"}
        before {@options = {:startkey=>["all", "fakefieldworker"], :endkey=>["all","fakefieldworker", {}], :page=>1, :per_page=>20, :view_name=>:by_all_view_with_created_by_created_at}}

        it_should_behave_like "viewing children as a field worker"
      end

      context "when status is not passed admin" do
        before {@options = {:startkey=>["all"], :endkey=>["all", {}], :page=>1, :per_page=>20, :view_name=>:by_all_view_name}}
        it_should_behave_like "viewing children by user with access to all data"
      end

      context "when status is not passed field_worker" do
        before {@options = {:startkey=>["all", "fakefieldworker"], :endkey=>["all","fakefieldworker", {}], :page=>1, :per_page=>20, :view_name=>:by_all_view_with_created_by_created_at}}
        it_should_behave_like "viewing children as a field worker"
      end

      context "when status is not passed field_worker and order is name" do
        before {@options = {:startkey=>["all", "fakefieldworker"], :endkey=>["all","fakefieldworker", {}], :page=>1, :per_page=>20, :view_name=>:by_all_view_with_created_by_name}}
        before {@params = {:order_by => 'name'}}
        it_should_behave_like "viewing children as a field worker"
      end

      context "when status is not passed field_worker, order is created_at and page is 2" do
        before {@options = {:view_name=>:by_all_view_with_created_by_created_at, :startkey=>["all", "fakefieldworker", {}], :endkey=>["all", "fakefieldworker"], :descending=>true, :page=>2, :per_page=>20}}
        before {@params = {:order_by => 'created_at', :page => 2}}
        it_should_behave_like "viewing children as a field worker"
      end
    end

    context "viewing reunited children" do
      before do
        @status = "reunited"
        @stubs = {:reunited? => true}
      end
      context "admin" do
        before { @options = {:startkey=>["reunited"], :endkey=>["reunited", {}], :page=>1, :per_page=>20, :view_name=>:by_all_view_name} }
        it_should_behave_like "viewing children by user with access to all data"
      end
      context "field worker" do
        before { @options = {:startkey=>["reunited", "fakefieldworker"], :endkey=>["reunited", "fakefieldworker", {}], :page=>1, :per_page=>20, :view_name=>:by_all_view_with_created_by_created_at}}
        it_should_behave_like "viewing children as a field worker"
      end
    end

    context "viewing flagged children" do
      before { @status = "flagged" }
      context "admin" do
        before {@options = {:startkey=>["flagged"], :endkey=>["flagged", {}], :page=>1, :per_page=>20, :view_name=>:by_all_view_name}}
        it_should_behave_like "viewing children by user with access to all data"
      end
      context "field_worker" do
        before {@options = {:startkey=>["flagged", "fakefieldworker"], :endkey=>["flagged", "fakefieldworker", {}], :page=>1, :per_page=>20, :view_name=>:by_all_view_with_created_by_created_at}}
        it_should_behave_like "viewing children as a field worker"
      end
    end

    context "viewing active children" do
      before do
        @status = "active"
        @stubs = {:reunited? => false}
      end
      context "admin" do
        before {@options = {:startkey=>["active"], :endkey=>["active", {}], :page=>1, :per_page=>20, :view_name=>:by_all_view_name}}
        it_should_behave_like "viewing children by user with access to all data"
      end
      context "field worker" do
        before {@options = {:startkey=>["active", "fakefieldworker"], :endkey=>["active", "fakefieldworker", {}], :page=>1, :per_page=>20, :view_name=>:by_all_view_with_created_by_created_at}}
        it_should_behave_like "viewing children as a field worker"
      end
    end

    describe "export all to PDF/CSV/CPIMS/Photo Wall" do
      before do
        fake_field_admin_login
        @params ||= {}
        controller.stub :paginated_collection => [], :render => true
      end
      it "should flash notice when exporting no records" do
        format = "cpims"
        @params.merge!(:format => format)
        get :index, @params
        expect(flash[:notice]).to eq("No Records Available!")
      end
    end
  end

  describe "GET show" do
    it 'does not assign child name in page name' do
      child = build :child, :unique_identifier => "1234"
      allow(controller).to receive :render
      get :show, :id => child.id
      expect(assigns[:page_name]).to eq("View Child 1234")
    end

    it "assigns the requested child" do
      allow(Child).to receive(:get).with("37").and_return(mock_child)
      get :show, :id => "37"
      expect(assigns[:child]).to equal(mock_child)
    end

    it 'should not fail if primary_photo_id is not present' do
      allow(User).to receive(:find_by_user_name).with("uname").and_return(user = double('user', :user_name => 'uname', :organisation => 'org'))
      child = Child.create('last_known_location' => "London", :created_by => "uname")
      child.create_unique_id
      allow(Child).to receive(:get).with("37").and_return(child)
      allow(Clock).to receive(:now).and_return(Time.parse("Jan 17 2010 14:05:32"))

      allow(controller).to receive :render
      get(:show, :format => 'csv', :id => "37")
    end

    it "should set current photo key as blank instead of nil" do
      allow(User).to receive(:find_by_user_name).with("uname").and_return(user = double('user', :user_name => 'uname', :organisation => 'org'))
      child = Child.create('last_known_location' => "London", :created_by => "uname")
      child.create_unique_id
      allow(Child).to receive(:get).with("37").and_return(child)
      assigns[child[:current_photo_key]] == ""
      get(:show, :format => 'json', :id => "37")
    end

    it "orders and assigns the forms" do
      allow(Child).to receive(:get).with("37").and_return(mock_child)
      expect(FormSection).to receive(:enabled_by_order).and_return([:the_form_sections])
      get :show, :id => "37"
      expect(assigns[:form_sections]).to eq([:the_form_sections])
    end

    it "should flash an error and go to listing page if the resource is not found" do
      allow(Child).to receive(:get).with("invalid record").and_return(nil)
      get :show, :id=> "invalid record"
      expect(flash[:error]).to eq("Child with the given id is not found")
      expect(response).to redirect_to(:action => :index)
    end

    it "should include duplicate records in the response" do
      allow(Child).to receive(:get).with("37").and_return(mock_child)
      duplicates = [Child.new(:name => "duplicated")]
      expect(Child).to receive(:duplicates_of).with("37").and_return(duplicates)
      get :show, :id => "37"
      expect(assigns[:duplicates]).to eq(duplicates)
    end
  end

  describe "GET new" do
    it "assigns a new child as @child" do
      allow(Child).to receive(:new).and_return(mock_child)
      get :new
      expect(assigns[:child]).to equal(mock_child)
    end

    it "orders and assigns the forms" do
      allow(Child).to receive(:new).and_return(mock_child)
      expect(FormSection).to receive(:enabled_by_order).and_return([:the_form_sections])
      get :new
      expect(assigns[:form_sections]).to eq([:the_form_sections])
    end
  end

  describe "GET edit" do
    it "assigns the requested child as @child" do
      allow(Child).to receive(:get).with("37").and_return(mock_child)
      expect(FormSection).to receive(:enabled_by_order)
      get :edit, :id => "37"
      expect(assigns[:child]).to equal(mock_child)
    end

    it "orders and assigns the forms" do
      allow(Child).to receive(:get).with("37").and_return(mock_child)
      expect(FormSection).to receive(:enabled_by_order).and_return([:the_form_sections])
      get :edit, :id => "37"
      expect(assigns[:form_sections]).to eq([:the_form_sections])
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested child" do
      expect(Child).to receive(:get).with("37").and_return(mock_child)
      expect(mock_child).to receive(:destroy)
      delete :destroy, :id => "37"
    end

    it "redirects to the children list" do
      allow(Child).to receive(:get).and_return(mock_child(:destroy => true))
      delete :destroy, :id => "1"
      expect(response).to redirect_to(children_url)
    end
  end

  describe "PUT update" do
    it "should sanitize the parameters if the params are sent as string(params would be as a string hash when sent from mobile)" do
      allow(User).to receive(:find_by_user_name).with("uname").and_return(user = double('user', :user_name => 'uname', :organisation => 'org'))
      child = Child.create('last_known_location' => "London", 'photo' => uploadable_photo, :created_by => "uname", :created_at => "Jan 16 2010 14:05:32")
      child.attributes = {'histories' => [] }
      child.save!

      allow(Clock).to receive(:now).and_return(Time.parse("Jan 17 2010 14:05:32"))
      histories = "[{\"datetime\":\"2013-02-01 04:49:29UTC\",\"user_name\":\"rapidftr\",\"changes\":{\"photo_keys\":{\"added\":[\"photo-671592136-2013-02-01T101929\"],\"deleted\":null}},\"user_organisation\":\"N\\/A\"}]"
      put :update, :id => child.id,
           :child => {
               :last_known_location => "Manchester",
               :histories => histories
           }

     expect(assigns[:child]['histories']).to eq(JSON.parse(histories))
    end

    it "should update child on a field and photo update" do
      allow(User).to receive(:find_by_user_name).with("uname").and_return(user = double('user', :user_name => 'uname', :organisation => 'org'))
      child = Child.create('last_known_location' => "London", 'photo' => uploadable_photo, :created_by => "uname")

      allow(Clock).to receive(:now).and_return(Time.parse("Jan 17 2010 14:05:32"))
      put :update, :id => child.id,
        :child => {
          :last_known_location => "Manchester",
          :photo => Rack::Test::UploadedFile.new(uploadable_photo_jeff) }

      expect(assigns[:child]['last_known_location']).to eq("Manchester")
      expect(assigns[:child]['_attachments'].size).to eq(2)
      updated_photo_key = assigns[:child]['_attachments'].keys.select {|key| key =~ /photo.*?-2010-01-17T140532/}.first
      expect(assigns[:child]['_attachments'][updated_photo_key]['data']).not_to be_blank
    end

    it "should update only non-photo fields when no photo update" do
      allow(User).to receive(:find_by_user_name).with("uname").and_return(user = double('user', :user_name => 'uname', :organisation => 'org'))
      child = Child.create('last_known_location' => "London", 'photo' => uploadable_photo, :created_by => "uname")

      put :update, :id => child.id,
        :child => {
          :last_known_location => "Manchester",
          :age => '7'}

      expect(assigns[:child]['last_known_location']).to eq("Manchester")
      expect(assigns[:child]['age']).to eq("7")
      expect(assigns[:child]['_attachments'].size).to eq(1)
    end

    it "should not update history on photo rotation" do
      allow(User).to receive(:find_by_user_name).with("uname").and_return(user = double('user', :user_name => 'uname', :organisation => 'org'))
      child = Child.create('last_known_location' => "London", 'photo' => uploadable_photo_jeff, :created_by => "uname")
      expect(Child.get(child.id)["histories"].size).to be 1

      expect{put(:update_photo, :id => child.id, :child => {:photo_orientation => "-180"})}.to_not change{Child.get(child.id)["histories"].size}
    end

    it "should allow a records ID to be specified to create a new record with a known id" do
      new_uuid = UUIDTools::UUID.random_create()
      put :update, :id => new_uuid.to_s,
        :child => {
            :id => new_uuid.to_s,
            :_id => new_uuid.to_s,
            :last_known_location => "London",
            :age => "7"
        }
      expect(Child.get(new_uuid.to_s)[:unique_identifier]).not_to be_nil
    end

    it "should update flag (cast as boolean) and flag message" do
      allow(User).to receive(:find_by_user_name).with("uname").and_return(user = double('user', :user_name => 'uname', :organisation => 'org'))
      child = Child.create('last_known_location' => "London", 'photo' => uploadable_photo, :created_by => "uname")
      put :update, :id => child.id,
        :child => {
          :flag => true,
          :flag_message => "Possible Duplicate"
        }
      expect(assigns[:child]['flag']).to be_truthy
      expect(assigns[:child]['flag_message']).to eq("Possible Duplicate")
    end

    it "should update history on flagging of record" do
      current_time_in_utc = Time.parse("20 Jan 2010 17:10:32UTC")
      current_time = Time.parse("20 Jan 2010 17:10:32")
      allow(Clock).to receive(:now).and_return(current_time)
      allow(current_time).to receive(:getutc).and_return current_time_in_utc
      allow(User).to receive(:find_by_user_name).with("uname").and_return(user = double('user', :user_name => 'uname', :organisation => 'org'))
      child = Child.create('last_known_location' => "London", 'photo' => uploadable_photo_jeff, :created_by => "uname")

      put :update, :id => child.id, :child => {:flag => true, :flag_message => "Test"}

      history = Child.get(child.id)["histories"].first
      expect(history['changes']).to have_key('flag')
      expect(history['datetime']).to eq("2010-01-20 17:10:32UTC")
    end

    it "should update the last_updated_by_full_name field with the logged in user full name" do
      allow(User).to receive(:find_by_user_name).with("uname").and_return(user = double('user', :user_name => 'uname', :organisation => 'org'))
      child = Child.new_with_user_name(user, {:name => 'existing child'})
      allow(Child).to receive(:get).with("123").and_return(child)
      expect(subject).to receive('current_user_full_name').and_return('Bill Clinton')

      put :update, :id => 123, :child => {:flag => true, :flag_message => "Test"}

      expect(child['last_updated_by_full_name']).to eq('Bill Clinton')
    end

    it "should not set photo if photo is not passed" do
      allow(User).to receive(:find_by_user_name).with("uname").and_return(user = double('user', :user_name => 'uname', :organisation => 'org'))
      child = Child.new_with_user_name(user, {:name => 'some name'})
      params_child = {"name" => 'update'}
      allow(controller).to receive(:current_user_name).and_return("user_name")
      expect(child).to receive(:update_properties_with_user_name).with("user_name", "", nil, nil, params_child)
      allow(Child).to receive(:get).and_return(child)
      put :update, :id => '1', :child => params_child
      end


    it "should redirect to redirect_url if it is present in params" do
      allow(User).to receive(:find_by_user_name).with("uname").and_return(user = double('user', :user_name => 'uname', :organisation => 'org'))
      child = Child.new_with_user_name(user, {:name => 'some name'})
      params_child = {"name" => 'update'}
      allow(controller).to receive(:current_user_name).and_return("user_name")
      expect(child).to receive(:update_properties_with_user_name).with("user_name", "", nil, nil, params_child)
      allow(Child).to receive(:get).and_return(child)
      put :update, :id => '1', :child => params_child, :redirect_url => '/children'
      expect(response).to redirect_to '/children'
    end

    it "should redirect to child page if redirect_url is not present in params" do
      allow(User).to receive(:find_by_user_name).with("uname").and_return(user = double('user', :user_name => 'uname', :organisation => 'org'))
      child = Child.new_with_user_name(user, {:name => 'some name'})

      params_child = {"name" => 'update'}
      allow(controller).to receive(:current_user_name).and_return("user_name")
      expect(child).to receive(:update_properties_with_user_name).with("user_name", "", nil, nil, params_child)
      allow(Child).to receive(:get).and_return(child)
      put :update, :id => '1', :child => params_child
      expect(response).to redirect_to "/children/#{child.id}"
    end

  end

  describe "GET search" do
    it "should not render error by default" do
      get(:search, :format => 'html')
      expect(assigns[:search]).to be_nil
    end

    it "should render error if search is invalid" do
      get(:search, :format => 'html', :query => '2'*160)
      search = assigns[:search]
      expect(search.errors).not_to be_empty
    end

    it "should stay in the page if search is invalid" do
      get(:search, :format => 'html', :query => '1'*160)
      expect(response).to render_template("search")
    end

    it "performs a search using the parameters passed to it" do
      search = double("search", :query => 'the child name', :valid? => true, :page => 1)
      allow(Search).to receive(:new).and_return(search)

      fake_results = ["fake_child","fake_child"]
      fake_full_results =  [:fake_child,:fake_child, :fake_child, :fake_child]
      expect(Child).to receive(:search).with(search, 1).and_return([fake_results, fake_full_results])
      get(:search, :format => 'html', :query => 'the child name')
      expect(assigns[:results]).to eq(fake_results)
    end

    describe "with no results" do
      before do
        get(:search, :query => 'blah')
      end

      it 'asks view to not show csv export link if there are no results' do
        expect(assigns[:results].size).to eq(0)
      end

      it 'asks view to display a "No results found" message if there are no results' do
        expect(assigns[:results].size).to eq(0)
      end

    end
  end

  describe "searching as field worker" do
    before :each do
      @session = fake_field_worker_login
    end
    it "should only list the children which the user has registered" do
      search = double("search", :query => 'some_name', :valid? => true, :page => 1)
      allow(Search).to receive(:new).and_return(search)

      fake_results = [:fake_child,:fake_child]
      fake_full_results =  [:fake_child,:fake_child, :fake_child, :fake_child]
      expect(Child).to receive(:search_by_created_user).with(search, @session.user_name, 1).and_return([fake_results, fake_full_results])

      get(:search, :query => 'some_name')
      expect(assigns[:results]).to eq(fake_results)
    end
  end

  it 'should export children using #respond_to_export' do
    child1 = build :child
    child2 = build :child
    controller.stub :paginated_collection => [ child1, child2 ], :render => true
    expect(controller).to receive(:YAY).and_return(true)

    expect(controller).to receive(:respond_to_export) { |format, children|
      format.mock { controller.send :YAY }
      expect(children).to eq([ child1, child2 ])
    }

    get :index, :format => :mock
  end

  it 'should export child using #respond_to_export' do
    child = build :child
    controller.stub :render => true
    expect(controller).to receive(:YAY).and_return(true)

    expect(controller).to receive(:respond_to_export) { |format, children|
      format.mock { controller.send :YAY }
      expect(children).to eq([ child ])
    }

    get :show, :id => child.id, :format => :mock
  end

  describe '#respond_to_export' do
    before :each do
      @child1 = build :child
      @child2 = build :child
      controller.stub :paginated_collection => [ @child1, @child2 ], :render => true
    end

    it "should handle full PDF" do
      expect_any_instance_of(Addons::PdfExportTask).to receive(:export).with([ @child1, @child2 ]).and_return('data')
      get :index, :format => :pdf
    end

    it "should handle Photowall PDF" do
      expect_any_instance_of(Addons::PhotowallExportTask).to receive(:export).with([ @child1, @child2 ]).and_return('data')
      get :index, :format => :photowall
    end

    it "should handle CSV" do
      expect_any_instance_of(Addons::CsvExportTask).to receive(:export).with([ @child1, @child2 ]).and_return('data')
      get :index, :format => :csv
    end

    it "should handle custom export addon" do
      mock_addon = double()
      mock_addon_class = double(:new => mock_addon, :id => "mock")
      RapidftrAddon::ExportTask.stub :active => [ mock_addon_class ]
      allow(controller).to receive(:authorize!)
      expect(mock_addon).to receive(:export).with([ @child1, @child2 ]).and_return('data')
      get :index, :format => :mock
    end

    it "should encrypt result" do
      expect_any_instance_of(Addons::CsvExportTask).to receive(:export).with([ @child1, @child2 ]).and_return('data')
      expect(controller).to receive(:export_filename).with([ @child1, @child2 ], Addons::CsvExportTask).and_return("test_filename")
      expect(controller).to receive(:encrypt_exported_files).with('data', 'test_filename').and_return(true)
      get :index, :format => :csv
    end

    it "should create a log_entry when record is exported" do
      fake_login User.new(:user_name => 'fakeuser', :organisation => "STC", :role_ids => ["abcd"])
      allow(@controller).to receive(:authorize!)
      expect_any_instance_of(RapidftrAddonCpims::ExportTask).to receive(:export).with([ @child1, @child2 ]).and_return('data')

      expect(LogEntry).to receive(:create!).with :type => LogEntry::TYPE[:cpims], :user_name => "fakeuser", :organisation => "STC", :child_ids => [@child1.id, @child2.id]

      get :index, :format => :cpims
    end

    it "should generate filename based on child ID and addon ID when there is only one child" do
      @child1.stub :short_id => 'test_short_id'
      expect(controller.send(:export_filename, [ @child1 ], Addons::PhotowallExportTask)).to eq("test_short_id_photowall.zip")
    end

    it "should generate filename based on username and addon ID when there are multiple children" do
      controller.stub :current_user_name => 'test_user'
      expect(controller.send(:export_filename, [ @child1, @child2 ], Addons::PdfExportTask)).to eq("test_user_pdf.zip")
    end

    it "should handle CSV" do
      expect_any_instance_of(Addons::CsvExportTask).to receive(:export).with([ @child1, @child2 ]).and_return('data')
      get :index, :format => :csv
    end

  end

  describe "PUT select_primary_photo" do
    before :each do
      @child = stub_model(Child, :id => "id")
      @photo_key = "key"
      allow(@child).to receive(:primary_photo_id=)
      allow(@child).to receive(:save)
      allow(Child).to receive(:get).with("id").and_return @child
    end

    it "set the primary photo on the child and save" do
      expect(@child).to receive(:primary_photo_id=).with(@photo_key)
      expect(@child).to receive(:save)

      put :select_primary_photo, :child_id => @child.id, :photo_id => @photo_key
    end

    it "should return success" do
      put :select_primary_photo, :child_id => @child.id, :photo_id => @photo_key

      expect(response).to be_success
    end

    context "when setting new primary photo id errors" do
      before :each do
        allow(@child).to receive(:primary_photo_id=).and_raise("error")
      end

      it "should return error" do
        put :select_primary_photo, :child_id => @child.id, :photo_id => @photo_key

        expect(response).to be_error
      end
    end
  end

  describe "PUT create" do
    it "should add the full user_name of the user who created the Child record" do
      expect(Child).to receive('new_with_user_name').and_return(child = Child.new)
      expect(controller).to receive('current_user_full_name').and_return('Bill Clinton')
      put :create, :child => {:name => 'Test Child' }
      expect(child['created_by_full_name']).to eq('Bill Clinton')
    end
  end

  describe "sync_unverified" do
    before :each do
      @user = build :user, :verified => false, :role_ids => []
      fake_login @user
    end

    it "should mark all children created as verified/unverifid based on the user" do
      @user.verified = true
      expect(Child).to receive(:new_with_user_name).with(@user, {"name" => "timmy", "verified" => @user.verified?}).and_return(child = Child.new)
      expect(child).to receive(:save).and_return true

      post :sync_unverified, {:child => {:name => "timmy"}, :format => :json}

      @user.verified = true
    end

    it "should set the created_by name to that of the user matching the params" do
      expect(Child).to receive(:new_with_user_name).and_return(child = Child.new)
      expect(child).to receive(:save).and_return true

      post :sync_unverified, {:child => {:name => "timmy"}, :format => :json}

      expect(child['created_by_full_name']).to eq @user.full_name
    end

    it "should update the child instead of creating new child everytime" do
      child = Child.new
      view = double(CouchRest::Model::Designs::View)
      expect(Child).to receive(:by_short_id).with(:key => '1234567').and_return(view)
      expect(view).to receive(:first).and_return(child)
      expect(controller).to receive(:update_child_from).and_return(child)
      expect(child).to receive(:save).and_return true

      post :sync_unverified, {:child => {:name => "timmy", :unique_identifier => '12345671234567'}, :format => :json}

      expect(child['created_by_full_name']).to eq @user.full_name
    end
  end

  describe "POST create" do
    it "should update the child record instead of creating if record already exists" do
      allow(User).to receive(:find_by_user_name).with("uname").and_return(user = double('user', :user_name => 'uname', :organisation => 'org'))
      child = Child.new_with_user_name(user, {:name => 'old name'})
      child.save
      fake_admin_login
      allow(controller).to receive(:authorize!)
      post :create, :child => {:unique_identifier => child.unique_identifier, :name => 'new name'}
      updated_child = Child.by_short_id(:key => child.short_id)
      expect(updated_child.all.size).to eq(1)
      expect(updated_child.first.name).to eq('new name')
    end
  end

end
