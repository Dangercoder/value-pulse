class PropertyAnalysisController < ApplicationController
  def analyze
    @address = params[:address]
    @additional_info = params[:additional_info]

    if @address.blank? || @address.length < 5
      respond_to do |format|
        format.html do
          flash[:error] = "Property address is required and must be at least 5 characters long."
          redirect_to root_path
        end
      end
      return
    end

    Turbo::StreamsChannel.verified_stream_name(
      "property_analysis_#{session.id}"
    )

    respond_to do |format|
      format.html do
        flash[:info] = "Your property analysis request has been submitted and is being processed."
        redirect_to root_path
      end

      format.turbo_stream do
        render turbo_stream: turbo_stream.update(
          "analysis_result",
          partial: "property_analysis/analyzing"
        )

       @analysis = PropertyAnalysis.create(
          address: @address,
          additional_info: @additional_info || "",
          state: :pending
        )

        Turbo::StreamsChannel.verified_stream_name(
          "property_analysis_#{@analysis.id}"
        )

        PropertyAnalysisJob.perform_later(@analysis.id, session.id.to_s)
      end
    end
  end
end
