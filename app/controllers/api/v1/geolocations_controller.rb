module Api
  module V1
    class GeolocationsController < ApplicationController
      def index
        geolocations = Geolocation.order(created_at: :desc)
        render json: GeolocationSerializer.new(geolocations).serializable_hash
      end

      def show
        geolocation = find_geolocation
        render json: GeolocationSerializer.new(geolocation).serializable_hash
      end

      def create
        ip_or_url = params.require(:ip_or_url)
        result = GeolocationLookupService.call(ip_or_url)

        if result.success?
          status = result.geolocation.previously_new_record? ? :created : :ok
          render json: GeolocationSerializer.new(result.geolocation).serializable_hash, status: status
        else
          render_error(422, "Unprocessable Entity", result.error)
        end
      end

      def destroy
        geolocation = find_geolocation
        geolocation.destroy!
        head :no_content
      end

      private

      def find_geolocation
        Geolocation.find_by!(ip_address: params[:ip_address])
      end
    end
  end
end
