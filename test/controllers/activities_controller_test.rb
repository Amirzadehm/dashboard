require 'test_helper'

class ActivitiesControllerTest < ActionController::TestCase
  include Devise::TestHelpers
  setup do
    @user = create(:user, total_lines: 15)
    sign_in(@user)

    @activity = create(:activity, user: @user)

    @admin = create(:admin)

    @script_level_prev = ScriptLevel.find(1)
    @script_level = ScriptLevel.find(2)
    @script_level_next = ScriptLevel.find(3)
    @script = @script_level.script

    @blank_image = File.read('test/fixtures/artist_image_blank.png', binmode: true)
    @good_image = File.read('test/fixtures/artist_image_1.png', binmode: true)
    @another_good_image = File.read('test/fixtures/artist_image_2.png', binmode: true)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:activities)
  end

  test "should get index with edmodo header" do
    @request.headers["Accept"] = "image/*"
    @request.headers["User-Agent"] = "Edmodo/14 CFNetwork/672.0.2 Darwin/14.0.0"
    get :index
    assert_response :success
    assert_not_nil assigns(:activities)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create activity" do
    assert_difference('Activity.count') do
      post :create, activity: {  }
    end

    assert_redirected_to activity_path(assigns(:activity))
  end

  test "logged in milestone" do
    # TODO actually test experiment instead of just stubbing it out
    ActivityHint.expects(:is_experimenting_feedback?).returns(false)

    # do all the logging
    @controller.expects :log_milestone
    @controller.expects :slog

    @controller.expects(:trophy_check).with(@user)

    assert_creates(LevelSource, Activity, UserLevel) do
      assert_does_not_create(GalleryActivity) do
        assert_difference('@user.reload.total_lines', 20) do # update total lines
          post :milestone, user_id: @user, script_level_id: @script_level, :lines => 20, :attempt => "1", :result => "true", :testResult => "100", :time => "1000", :app => "test", :program => "<hey>"
        end
      end
    end

    assert_response :success

    expected_response = {"previous_level"=>"/s/#{@script.id}/level/#{@script_level_prev.id}",
                         "total_lines"=>35,
                         "redirect"=>"/s/#{@script.id}/level/#{@script_level_next.id}",
                         "level_source"=>"http://test.host/sh/#{assigns(:level_source).id}",
                         "save_to_gallery_url"=>"/gallery?gallery_activity%5Bactivity_id%5D=#{assigns(:activity).id}",
                         "design"=>"white_background"}


    assert_equal expected_response, JSON.parse(@response.body)
  end


  test "logged in milestone should save to gallery when passing an impressive level" do
    # do all the logging
    @controller.expects :log_milestone
    @controller.expects :slog

    @controller.expects(:trophy_check).with(@user)

    assert_creates(LevelSource, Activity, UserLevel, GalleryActivity) do
      assert_difference('@user.reload.total_lines', 20) do # update total lines
        post :milestone, user_id: @user, script_level_id: @script_level, :lines => 20, :attempt => "1", :result => "true", :testResult => "100", :time => "1000", :app => "test", :program => "<hey>", :save_to_gallery => true, image: Base64.encode64(@good_image)
      end
    end

    assert_response :success

    expected_response = {"previous_level"=>"/s/#{@script.id}/level/#{@script_level_prev.id}",
                         "total_lines"=>35,
                         "redirect"=>"/s/#{@script.id}/level/#{@script_level_next.id}",
                         "level_source"=>"http://test.host/sh/#{assigns(:level_source).id}",
                         "save_to_gallery_url"=>"/gallery?gallery_activity%5Bactivity_id%5D=#{assigns(:activity).id}",
                         "design"=>"white_background"}

    assert_equal expected_response, JSON.parse(@response.body)

    # created gallery activity and activity for user
    assert_equal @user, Activity.last.user
    assert_equal @user, GalleryActivity.last.user
    assert_equal Activity.last, GalleryActivity.last.activity
  end

  test "logged in milestone not passing" do
    # TODO actually test experiment instead of just stubbing it out
    ActivityHint.expects(:is_experimenting_feedback?).returns(false)

    # do all the logging
    @controller.expects :log_milestone
    @controller.expects :slog

    @controller.expects(:trophy_check).with(@user) # TODO we don't actually need to check if not passing

    assert_creates(LevelSource, Activity, UserLevel) do
      assert_does_not_create(GalleryActivity) do
          assert_no_difference('@user.reload.total_lines') do # don't update total lines
            post :milestone, user_id: @user, script_level_id: @script_level, :lines => 20, :attempt => "1", :result => "false", :testResult => "10", :time => "1000", :app => "test", :program => "<hey>"
          end
      end
    end

    assert_response :success

    expected_response = {"previous_level"=>"/s/1/level/1",
                         "message"=>"try again",
                         "level_source"=>"http://test.host/sh/#{assigns(:level_source).id}",
                         "design"=>"white_background"}

    assert_equal expected_response, JSON.parse(@response.body)
  end


  test "logged in milestone with image not passing" do
    # TODO actually test experiment instead of just stubbing it out
    ActivityHint.expects(:is_experimenting_feedback?).returns(false)

    # do all the logging
    @controller.expects :log_milestone
    @controller.expects :slog

    @controller.expects(:trophy_check) # TODO we don't actually need to check if not passing

    assert_creates(LevelSource, Activity, UserLevel, LevelSourceImage) do
      assert_does_not_create(GalleryActivity) do
        assert_no_difference('@user.reload.total_lines') do # don't update total lines
          post :milestone, user_id: @user, script_level_id: @script_level, :lines => 20, :attempt => "1", :result => "false", :testResult => "10", :time => "1000", :app => "test", :program => "<hey>", image: Base64.encode64(@good_image), :save_to_gallery => true
        end
      end
    end

    assert_equal @good_image.size, LevelSourceImage.last.image.size

    assert_response :success

    expected_response = {"previous_level"=>"/s/1/level/1",
                         "message"=>"try again",
                         "level_source"=>"http://test.host/sh/#{assigns(:level_source).id}",
                         "design"=>"white_background"}

    assert_equal expected_response, JSON.parse(@response.body)
  end

  test "logged in milestone with image" do
    # TODO actually test experiment instead of just stubbing it out
    ActivityHint.expects(:is_experimenting_feedback?).returns(false)

    # do all the logging
    @controller.expects :log_milestone
    @controller.expects :slog

    @controller.expects(:trophy_check)

    assert_creates(LevelSource, Activity, UserLevel, LevelSourceImage) do
      assert_does_not_create(GalleryActivity) do
        assert_difference('@user.reload.total_lines', 20) do # update total lines
          post :milestone, user_id: @user, script_level_id: @script_level, :lines => 20, :attempt => "1", :result => "true", :testResult => "100", :time => "1000", :app => "test", :program => "<hey>", :image => Base64.encode64(@good_image)
        end
      end
    end

    assert_equal @good_image.size, LevelSourceImage.last.image.size

    assert_response :success

    expected_response = {"previous_level"=>"/s/#{@script.id}/level/#{@script_level_prev.id}",
                         "total_lines"=>35,
                         "redirect"=>"/s/#{@script.id}/level/#{@script_level_next.id}",
                         "level_source"=>"http://test.host/sh/#{assigns(:level_source).id}",
                         "save_to_gallery_url"=>"/gallery?gallery_activity%5Bactivity_id%5D=#{assigns(:activity).id}",
                         "design"=>"white_background"}

    assert_equal expected_response, JSON.parse(@response.body)
  end

  test "logged in milestone with existing level source and level source image" do
    # TODO actually test experiment instead of just stubbing it out
    ActivityHint.expects(:is_experimenting_feedback?).returns(false)

    # do all the logging
    @controller.expects :log_milestone
    @controller.expects :slog

    @controller.expects(:trophy_check)

    program = "<whatever>"
    
    level_source = LevelSource.lookup(@script_level.level, program) # creates it, doesn't just look it up, despite the name
    level_source_image = LevelSourceImage.find_or_create_by(level_source_id: level_source.id) do |ls|
      ls.image = @good_image
    end
    assert_equal @good_image.size, level_source_image.reload.image.size

    assert_creates(Activity, UserLevel) do
      assert_does_not_create(LevelSource, LevelSourceImage, GalleryActivity) do
        assert_difference('@user.reload.total_lines', 20) do # update total lines
          post :milestone, user_id: @user, script_level_id: @script_level, :lines => 20, :attempt => "1", :result => "true", :testResult => "100", :time => "1000", :app => "test", :program => program, :image => Base64.encode64(@good_image)
        end
      end
    end

    assert_equal @good_image.size, level_source_image.reload.image.size

    assert_response :success

    assert_equal level_source, assigns(:level_source)

    expected_response = {"previous_level"=>"/s/#{@script.id}/level/#{@script_level_prev.id}",
                         "total_lines"=>35,
                         "redirect"=>"/s/#{@script.id}/level/#{@script_level_next.id}",
                         "level_source"=>"http://test.host/sh/#{assigns(:level_source).id}",
                         "save_to_gallery_url"=>"/gallery?gallery_activity%5Bactivity_id%5D=#{assigns(:activity).id}",
                         "design"=>"white_background"}

    assert_equal expected_response, JSON.parse(@response.body)
  end

  test "logged in milestone with existing level source and level source image updates image if old image was blank" do
    # TODO actually test experiment instead of just stubbing it out
    ActivityHint.expects(:is_experimenting_feedback?).returns(false)


    program = "<whatever>"
    
    level_source = LevelSource.lookup(@script_level.level, program) # creates it, doesn't just look it up, despite the name
    level_source_image = LevelSourceImage.find_or_create_by(level_source_id: level_source.id) do |ls|
      ls.image = @blank_image
    end

    assert_creates(Activity, UserLevel) do
      assert_does_not_create(LevelSource, LevelSourceImage, GalleryActivity) do
        assert_difference('@user.reload.total_lines', 20) do # update total lines
          post :milestone, user_id: @user, script_level_id: @script_level, :lines => 20, :attempt => "1", :result => "true", :testResult => "100", :time => "1000", :app => "test", :program => program, :image => Base64.encode64(@good_image)
        end
      end
    end

    assert_equal @good_image.size, level_source_image.reload.image.size

    assert_response :success

    assert_equal level_source, assigns(:level_source)

    expected_response = {"previous_level"=>"/s/#{@script.id}/level/#{@script_level_prev.id}",
                         "total_lines"=>35,
                         "redirect"=>"/s/#{@script.id}/level/#{@script_level_next.id}",
                         "level_source"=>"http://test.host/sh/#{assigns(:level_source).id}",
                         "save_to_gallery_url"=>"/gallery?gallery_activity%5Bactivity_id%5D=#{assigns(:activity).id}",
                         "design"=>"white_background"}

    assert_equal expected_response, JSON.parse(@response.body)
  end

  test "logged in milestone with existing level source and level source image does not update image if new image is blank" do
    # TODO actually test experiment instead of just stubbing it out
    ActivityHint.expects(:is_experimenting_feedback?).returns(false)


    program = "<whatever>"
    
    level_source = LevelSource.lookup(@script_level.level, program) # creates it, doesn't just look it up, despite the name
    level_source_image = LevelSourceImage.find_or_create_by(level_source_id: level_source.id) do |ls|
      ls.image = @good_image
    end

    assert_creates(Activity, UserLevel) do
      assert_does_not_create(LevelSource, LevelSourceImage, GalleryActivity) do
        assert_difference('@user.reload.total_lines', 20) do # update total lines
          post :milestone, user_id: @user, script_level_id: @script_level, :lines => 20, :attempt => "1", :result => "true", :testResult => "100", :time => "1000", :app => "test", :program => program, :image => Base64.encode64(@blank_image)
        end
      end
    end

    assert_equal @good_image.size, level_source_image.reload.image.size

    assert_response :success

    assert_equal level_source, assigns(:level_source)

    expected_response = {"previous_level"=>"/s/#{@script.id}/level/#{@script_level_prev.id}",
                         "total_lines"=>35,
                         "redirect"=>"/s/#{@script.id}/level/#{@script_level_next.id}",
                         "level_source"=>"http://test.host/sh/#{assigns(:level_source).id}",
                         "save_to_gallery_url"=>"/gallery?gallery_activity%5Bactivity_id%5D=#{assigns(:activity).id}",
                         "design"=>"white_background"}

    assert_equal expected_response, JSON.parse(@response.body)
  end

  test "logged in milestone with existing level source and level source image does not update image if old image is good" do
    # TODO actually test experiment instead of just stubbing it out
    ActivityHint.expects(:is_experimenting_feedback?).returns(false)


    program = "<whatever>"
    
    level_source = LevelSource.lookup(@script_level.level, program) # creates it, doesn't just look it up, despite the name
    level_source_image = LevelSourceImage.find_or_create_by(level_source_id: level_source.id) do |ls|
      ls.image = @good_image
    end

    assert_creates(Activity, UserLevel) do
      assert_does_not_create(LevelSource, LevelSourceImage, GalleryActivity) do
        assert_difference('@user.reload.total_lines', 20) do # update total lines
          post :milestone, user_id: @user, script_level_id: @script_level, :lines => 20, :attempt => "1", :result => "true", :testResult => "100", :time => "1000", :app => "test", :program => program, :image => Base64.encode64(@another_good_image)
        end
      end
    end

    assert_equal @good_image.size, level_source_image.reload.image.size

    assert_response :success

    assert_equal level_source, assigns(:level_source)

    expected_response = {"previous_level"=>"/s/#{@script.id}/level/#{@script_level_prev.id}",
                         "total_lines"=>35,
                         "redirect"=>"/s/#{@script.id}/level/#{@script_level_next.id}",
                         "level_source"=>"http://test.host/sh/#{assigns(:level_source).id}",
                         "save_to_gallery_url"=>"/gallery?gallery_activity%5Bactivity_id%5D=#{assigns(:activity).id}",
                         "design"=>"white_background"}

    assert_equal expected_response, JSON.parse(@response.body)
  end


  # TODO actually test trophies

  test "anonymous milestone starting with empty session saves progress in section" do
    sign_out @user
    
    # do all the logging
    @controller.expects :log_milestone
    @controller.expects :slog
    
    @controller.expects(:trophy_check).never # no trophy if not logged in

    assert_creates(LevelSource) do
      assert_does_not_create(Activity, UserLevel, LevelSourceImage, GalleryActivity) do
        post :milestone, user_id: 0, script_level_id: @script_level, :lines => "1", :attempt => "1", :result => "true", :testResult => "100", :time => "1000", :app => "test", :program => "<hey>", :save_to_gallery => true
      end
    end

    # record activity in session
    expected_progress = {@script_level.level_id => 100}
    assert_equal expected_progress, session["progress"]

    # record the total lines of code in session
    assert_equal 1, session['lines']
    
    assert_response :success

    expected_response = {"previous_level"=>"/s/#{@script.id}/level/#{@script_level_prev.id}",
                         "total_lines"=>1,
                         "redirect"=>"/s/#{@script.id}/level/#{@script_level_next.id}",
                         "level_source"=>"http://test.host/sh/#{assigns(:level_source).id}",
                         "design"=>"white_background"}

    assert_equal expected_response, JSON.parse(@response.body)
  end

  test "anonymous milestone with existing session adds progress in session" do
    # TODO actually test experiment instead of just stubbing it out
    ActivityHint.expects(:is_experimenting_feedback?).returns(false)

    sign_out @user
    
    # set up existing session
    session['progress'] = {@script_level_prev.level_id => 50}
    session['lines'] = 10

    # do all the logging
    @controller.expects :log_milestone
    @controller.expects :slog

    @controller.expects(:trophy_check).never # no trophy if not logged in
    
    assert_creates(LevelSource) do
      assert_does_not_create(Activity, UserLevel, LevelSourceImage, GalleryActivity) do
        post :milestone, user_id: 0, script_level_id: @script_level, :lines => "1", :attempt => "1", :result => "true", :testResult => "100", :time => "1000", :app => "test", :program => "<hey>"
      end
    end

    # record activity in session
    expected_progress = {@script_level_prev.level_id => 50, @script_level.level_id => 100}
    assert_equal expected_progress, session['progress']

    # record the total lines of code in session
    assert_equal 11, session['lines']
    
    assert_response :success

    expected_response = {"previous_level"=>"/s/#{@script.id}/level/#{@script_level_prev.id}",
                         "total_lines"=>11,
                         "redirect"=>"/s/#{@script.id}/level/#{@script_level_next.id}",
                         "level_source"=>"http://test.host/sh/#{assigns(:level_source).id}",
                         "design"=>"white_background"}

    assert_equal expected_response, JSON.parse(@response.body)
  end

  test "anonymous milestone not passing" do
    # TODO actually test experiment instead of just stubbing it out
    ActivityHint.expects(:is_experimenting_feedback?).returns(false)

    sign_out @user
    
    session['lines'] = 10

    # do all the logging
    @controller.expects :log_milestone
    @controller.expects :slog
    
    assert_creates(LevelSource) do
      assert_does_not_create(Activity, UserLevel, LevelSourceImage, GalleryActivity) do
        post :milestone, user_id: 0, script_level_id: @script_level, :lines => "100", :attempt => "1", :result => "false", :testResult => "0", :time => "1000", :app => "test", :program => "<hey>"
      end
    end

    # record activity in session
    expected_progress = {@script_level.level_id => 0}
    assert_equal expected_progress, session["progress"]

    # lines in session does not change
    assert_equal 10, session['lines']
    
    assert_response :success
    expected_response = {"previous_level"=>"/s/1/level/1",
                         "message"=>"try again",
                         "level_source"=>"http://test.host/sh/#{assigns(:level_source).id}",
                         "design"=>"white_background"}
    assert_equal expected_response, JSON.parse(@response.body)
  end

  test "anonymous milestone with image saves image but does not save to gallery" do
    sign_out @user
    
    # set up existing session
    session['progress'] = {@script_level_prev.level_id => 50}
    session['lines'] = 10

    # do all the logging
    @controller.expects :log_milestone
    @controller.expects :slog

    @controller.expects(:trophy_check).never # no trophy if not logged in
    
    assert_creates(LevelSource, LevelSourceImage) do
      assert_does_not_create(Activity, UserLevel, GalleryActivity) do
        post :milestone, user_id: 0, script_level_id: @script_level, :lines => "1", :attempt => "1", :result => "true", :testResult => "100", :time => "1000", :app => "test", :program => "<hey>", :save_to_gallery => true, image: Base64.encode64(@good_image)
      end
    end

    # record activity in session
    expected_progress = {@script_level_prev.level_id => 50, @script_level.level_id => 100}
    assert_equal expected_progress, session['progress']

    # record the total lines of code in session
    assert_equal 11, session['lines']
    
    assert_response :success

    expected_response = {"previous_level"=>"/s/#{@script.id}/level/#{@script_level_prev.id}",
                         "total_lines"=>11,
                         "redirect"=>"/s/#{@script.id}/level/#{@script_level_next.id}",
                         "level_source"=>"http://test.host/sh/#{assigns(:level_source).id}",
                         "design"=>"white_background"}

    assert_equal expected_response, JSON.parse(@response.body)
  end


  test "should show activity" do
    get :show, id: @activity
    assert_response :success
  end

  test "admin should get edit" do
    sign_in @admin

    get :edit, id: @activity
    assert_response :success
  end

  test "admin should update activity" do
    sign_in @admin
    patch :update, id: @activity, activity: {  }
    assert_redirected_to activity_path(assigns(:activity))
  end

  test "user cannot update activity" do
    sign_in @user
    patch :update, id: @activity, activity: { }

    assert_response :forbidden
  end

  test "admin should destroy activity" do
    sign_in @admin
    assert_difference('Activity.count', -1) do
      delete :destroy, id: @activity
    end

    assert_redirected_to activities_path
  end

  test "user cannot destroy activity" do
    sign_in @user
    assert_no_difference('Activity.count') do
      delete :destroy, id: @activity
    end

    assert_response 403
  end

end
