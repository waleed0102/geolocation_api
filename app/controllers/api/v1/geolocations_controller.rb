module Api
  module V1
    class GeolocationsController < ApplicationController
      def index
        page     = [params.fetch(:page, 1).to_i, 1].max
        per_page = [[params.fetch(:per_page, 25).to_i, 1].max, 100].min

        geolocations = Geolocation.order(created_at: :desc)
                                  .limit(per_page)
                                  .offset((page - 1) * per_page)
        total = Geolocation.count

        render json: GeolocationSerializer.new(geolocations)
                                          .serializable_hash
                                          .merge(meta: { total: total, page: page, per_page: per_page })
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
        ip = begin
          IPAddr.new(params[:ip_address]).to_s
        rescue IPAddr::InvalidAddressError, IPAddr::AddressFamilyError
          params[:ip_address]
        end
        Geolocation.find_by!(ip_address: ip)
      end
    end
  end
end
