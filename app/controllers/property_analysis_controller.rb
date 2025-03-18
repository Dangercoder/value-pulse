class PropertyAnalysisController < ApplicationController
  def analyze
    @address = params[:address]
    @additional_info = params[:additional_info]

    # Validate address
    if @address.blank? || @address.length < 5
      respond_to do |format|
        format.html do
          flash[:error] = "Property address is required and must be at least 5 characters long."
          redirect_to root_path
        end

        format.turbo_stream do
          render turbo_stream: turbo_stream.update(
            "analysis_result",
            partial: "property_analysis/error",
            locals: {
              message: "Property address is required and must be at least 5 characters long."
            }
          )
        end
      end
      return
    end

    # Subscribe the user to their own analysis channel
    Turbo::StreamsChannel.verified_stream_name(
      "property_analysis_#{session.id.to_s}"
    )

    respond_to do |format|
      format.html do
        # Handle HTML response - redirect or render a template
        flash[:info] = "Your property analysis request has been submitted and is being processed."
        redirect_to root_path
      end

      format.turbo_stream do
        # First show the placeholder "analyzing" message
        render turbo_stream: turbo_stream.update(
          "analysis_result",
          partial: "property_analysis/analyzing"
        )

        # Then enqueue the actual analysis job
        PropertyAnalysisJob.perform_later(@address, @additional_info, session.id.to_s)
      end
    end
  end
end
