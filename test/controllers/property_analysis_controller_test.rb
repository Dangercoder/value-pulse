require "test_helper"

class PropertyAnalysisControllerTest < ActionDispatch::IntegrationTest
  test "should redirect with error for blank address" do
    post analyze_property_url, params: { address: "" }
    assert_redirected_to root_path
    assert_equal "Property address is required and must be at least 5 characters long.", flash[:error]
  end

  test "should redirect with error for address that is too short" do
    post analyze_property_url, params: { address: "123" }
    assert_redirected_to root_path
    assert_equal "Property address is required and must be at least 5 characters long.", flash[:error]
  end

  test "should return error via turbo stream for invalid address" do
    post analyze_property_url, params: { address: "" },
         headers: { "Accept" => "text/vnd.turbo-stream.html" },
         xhr: true

    assert_response :success
    assert_match /<turbo-stream action="update" target="analysis_result">/, @response.body
    assert_includes @response.body, "Property address is required and must be at least 5 characters long"
    assert_includes @response.body, "Validation Error"
  end

  test "should redirect with info message for valid address HTML request" do
    post analyze_property_url, params: { address: "123 Main Street" }
    assert_redirected_to root_path
    assert_equal "Your property analysis request has been submitted and is being processed.", flash[:info]
  end

  test "should render analyzing partial for turbo stream with valid address" do
    post analyze_property_url, params: { address: "123 Main Street" },
         headers: { "Accept" => "text/vnd.turbo-stream.html" },
         xhr: true

    assert_response :success
    assert_match /<turbo-stream action="update" target="analysis_result">/, @response.body
    assert_includes @response.body, "Analyzing Property"
    assert_includes @response.body, "Processing Your Request"
  end

  test "should enqueue PropertyAnalysisJob for valid address" do
    assert_enqueued_with(job: PropertyAnalysisJob) do
      post analyze_property_url,
           params: { address: "123 Main Street", additional_info: "Built in 2010" },
           headers: { "Accept" => "text/vnd.turbo-stream.html" },
           xhr: true
    end
  end
end
