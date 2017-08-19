class VideosController < ApplicationController
  prepend_before_action :authentication_check


  #@path [GET] /videos
  #
  #@summary Returns the list of Video Recored By User
  #

  def index
    offset = 0
    per_page = 500

    if params[:page] && params[:per_page]
      offset = (params[:page].to_i - 1) * params[:per_page].to_i
      per_page = params[:per_page].to_i

    end

    if per_page > 500
      per_page = 500
    end

    videos = if !current_user.permissions?(['admin.user', 'ticket.agent'])
               Video.where(user_id: current_user.id ).order(user_id: 'ASC').offset(offset).limit(per_page)
             else
               Video.all.order(user_id: 'ASC').offset(offset).limit(per_page)
             end

    if params[:expand]
      list = []
      videos.each { |video|
        list.push video
      }
      render json: list, status: :ok
      return
    end

    if params[:full]
      assets = {}
      item_ids = []
      users.each { |item|
        item_ids.push item.id
        assets = item.assets(assets)
      }
      render json: {
          record_ids: item_ids,
          assets: assets,
      },status: :ok
      return
    end

    videos.all = []

    videos.each { |video|

      videos_all.push Video.lookup(user_id: user_id)

    }
    render json: videos_all, status: :ok
  end




end