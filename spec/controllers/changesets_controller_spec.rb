require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ChangesetsController do  
  it_should_behave_like EveryProjectAreaController

  before do
    @project = permit_access_with_current_project! :name => 'Any'
    @changesets = [mock_model(Changeset, :revision => 'R10', :log => 'L1', :author => 'A1', :revised_at => 1.month.ago)]
    @proxy = @project.stub_association!(:changesets)
  end
  
  describe "handling GET /changesets" do
    before do
      @proxy.stub!(:paginate).and_return(@changesets)
    end
    
    def do_get
      get :index, :project_id => @project.to_param    
    end

    it "should find the changesets" do
      do_get
      assigns[:changesets].should == @changesets
    end

    it "should find changesets" do
      @proxy.should_receive(:paginate).
        with(:per_page=>nil, :page=>nil, :order=>'changesets.revised_at DESC', :include=>[:user]).
        and_return(@changesets)
      do_get
    end

    it_should_successfully_render_template('index')
  end

  describe "handling GET /changesets.rss" do
    before(:each) do
      Changeset.stub!(:to_rss)
      @proxy.stub!(:paginate).and_return(@changesets)
    end
    
    def do_get(options = {})
      get :index, options.merge(:format => 'rss', :project_id => @project.to_param)
    end
    
    it "should be successful" do
      do_get
      response.should be_success
    end
  
    it "should find changesets" do
      @proxy.should_receive(:paginate).
        with(:per_page=>10, :page=>1, :order=>'changesets.revised_at DESC', :include=>[:user]).
        and_return(@changesets)
      do_get
    end

    it "should render the found milestones as RSS" do
      Changeset.should_receive(:to_rss).with(@changesets).and_return("RSS")
      do_get :completed => '1'
      response.body.should == "RSS"
      response.content_type.should == "application/rss+xml"
    end
  end

  describe "handling GET /changesets/show" do
    describe 'if the record can be found' do
      before do
        @changeset = @changesets.first
        @next_changeset = @changesets.last
        @proxy.stub!(:find_by_revision).and_return(@changeset)
        @changeset.stub!(:next_by_project).and_return(@next_changeset)
        @changeset.stub!(:previous_by_project).and_return(nil)
      end
      
      def do_get
        get :show, :project_id => @project.to_param, :id => '1'        
      end

      
      it "should find the changeset" do
        @proxy.should_receive(:find_by_revision).
          with('1', :include => [:changes, :user]).and_return(@changeset)
        do_get
        assigns[:changeset].should == @changeset
      end


      it "should find the previous and next changeset" do
        @changeset.should_receive(:next_by_project).
          with(@project).and_return(@next_changeset)
        @changeset.should_receive(:previous_by_project).
          with(@project).and_return(nil)
        do_get
        assigns[:previous_changeset].should be_nil
        assigns[:next_changeset].should == @next_changeset
      end

      it_should_successfully_render_template('show')

    end

    describe 'if the record CANNOT be found' do
      before do
        @proxy.should_receive(:find_by_revision).
          with('-1', :include => [:changes, :user]).and_return(nil)        
      end

      it "should raise an error (404)" do
        lambda { get :show, :project_id => @project.to_param, :id => '-1' }.should raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

end