module Spree
  module Admin
    class MetafieldsController < Spree::Admin::BaseController
      before_action :set_resource
      before_action :load_data, only: [:edit, :update]

      include Spree::Admin::MetafieldsHelper

      def edit
        # Metafields are built automatically by the sorted_metafields helper
      end

      def update
        if @resource.update(permitted_metafields_params)
          flash[:success] = flash_message_for(@resource, :updated)
          redirect_to edit_admin_metafield_path(@resource, resource_type: @resource.class.to_s)
        else
          render :edit, status: :unprocessable_entity
        end
      end

      private

      def permitted_metafields_params
        params.require(@resource.model_name.param_key).permit(
          metafields_attributes: [:id, :metafield_definition_id, :value, :_destroy]
        )
      end

      def resource_class
        @resource_class ||= begin
          klass = params[:resource_type]
          metafield_definition_owner_types.find { |allowed_class| allowed_class.to_s == klass } ||
            raise(ActiveRecord::RecordNotFound, "Resource type not found")
        end
      end

      def set_resource
        @resource = if resource_class.respond_to?(:friendly)
                     resource_class.friendly.find(params[:id])
                   else
                     resource_class.find(params[:id])
                   end
      end

      def load_data
        @resource_name = @resource.try(:name) || @resource.try(:title) || "#{@resource.class.name} ##{@resource.id}"
        @has_definitions = Spree::MetafieldDefinition.for_owner_type(@resource.class.to_s).exists?

        @back_path = case @resource.class.name
        when 'Spree::Product'
          spree.edit_admin_product_path(@resource)
        when 'Spree::Variant'
          spree.edit_admin_product_variant_path(@resource.product, @resource)
        when 'Spree::Order'
          spree.edit_admin_order_path(@resource)
        when Spree.user_class.to_s
          spree.edit_admin_user_path(@resource)
        when 'Spree::Store'
          spree.edit_admin_store_path
        when 'Spree::Taxon'
          spree.edit_admin_taxonomy_taxon_path(@resource.taxonomy, @resource)
        when 'Spree::Taxonomy'
          spree.admin_taxonomy_path(@resource)
        else
          [:edit, :admin, @resource]
        end
      end
    end
  end
end
