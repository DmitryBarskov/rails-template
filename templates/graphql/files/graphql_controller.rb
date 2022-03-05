class GraphqlController < ApplicationController
  def execute
    render json: execute_query
  rescue StandardError => e
    raise e unless Rails.env.development?
    handle_error_in_development(e)
  end

  private

  def execute_query
    ApplicationSchema.execute(
      params[:query],
      variables: prepare_variables(params[:variables]),
      context: execution_context.deep_symbolize_keys,
      operation_name: params[:operationName]
    )
  end

  def execution_context
    current_user_context.merge(extensions: prepare_variables(params[:extensions]))
  end

  def current_user_context
    return {} unless respond_to?(:current_user)

    {
      current_user: current_user,
      token: token,
      token_payload: payload
    }
  end

  def prepare_variables(variables_param)
    case variables_param
    when String
      if variables_param.present?
        JSON.parse(variables_param) || {}
      else
        {}
      end
    when Hash
      variables_param
    when ActionController::Parameters
      variables_param.to_unsafe_hash
    when nil
      {}
    else
      raise ArgumentError, "Unexpected parameter: #{variables_param}"
    end
  end

  def handle_error_in_development(e)
    logger.error e.message
    logger.error e.backtrace.join("\n")

    error = { errors: [{ message: e.message, backtrace: e.backtrace }], data: {} }

    render json: error, status: :internal_server_error
  end
end
