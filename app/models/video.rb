class Video < ApplicationModel

  require 'google/cloud/storage'
  require 'google/cloud/video_intelligence/v1beta1'
  require 'streamio-ffmpeg'
  require "google/cloud/speech"
  require "google/cloud/language"
  require 'uri'
  require 'net/http'
  require 'json'

  include HasActivityStreamLog
  include Blockchain




  #@user_id
  #@video_hash
  #@video_storageUrl
  #@speech
  #@video_lables
  #@audio_labels
  #processed
  #This model stores video related files
  # The Idea of the Video Model is to Collect Video From the Users and Then Process It Once Process Respond with notification
  # and creating Ticket once understood which means Above a threshold for the User which is trying to submit the Video for a
  # Certain Ticket then a ticket will be created with Labels and Tags Only So that rest can be provided
  # We have to generate slangs which means labels will generate the full sentences
  #
  #

  activity_stream_permission 'ticket.customer'


  belongs_to :user


  after_create  :create_hash, :store_to_cloud, :get_labels, :get_speech_text, :process_video, :get_ibm_labels



  def store_to_cloud


    storage = Google::Cloud::Storage.new(
        project: "river-176215",
        keyfile: "config/google_settings.json"
    )


    bucket = storage.bucket "tidy-layout-9458"

    #Before Upload Extract Audio Using ffmpeg library



    intialFile = File.extname self.video_storageUrl



    movie = FFMPEG::Movie.new(self.video_storageUrl)

    movie_split_path = self.video_storageUrl.split(".")


    another_path = movie_split_path[0] + ".mp4"

    if intialFile == ".mp4"
      true
      puts "This is a MP4 File it will not be converted"
      comp = File.basename another_path
      path = "#{user_id}/#{self.video_hash}/#{comp}"
      bucket.create_file another_path, path, acl:"public", metadata: movie.metadata[:streams][0]

    else
      another_movie = movie.transcode(another_path)
      comp = File.basename another_path
      path = "#{user_id}/#{self.video_hash}/#{comp}"
      bucket.create_file another_movie.path, path, acl:"public", metadata: movie.metadata[:streams][0]

    end

    bitrate = movie.audio_streams[0][:bitrate]

    sample_rate = movie.audio_streams[0][:sample_rate]

    puts bitrate


    #Creating Audio File Path

    splitPath = self.video_storageUrl.split(".")

    mp3_path = splitPath[0] + ".flac"


    audio = movie.transcode(mp3_path, {:ab => bitrate, custom: %w(-ac 1)} )
    #audio = movie.transcode(mp3_path, %w(-ac 1  ))


    puts  audio.metadata[:streams][0][:duration]

    basename = File.basename mp3_path

    audio_path = "#{user_id}/#{self.video_hash}/#{basename}"




    bucket.create_file audio.path, audio_path, acl: "public", metadata: audio.metadata[:streams][0]

    update_column(:audio_url, audio_path)
    update_column(:audio_sample_rate, sample_rate)




    update_column(:video_storageUrl, path)
    cache_delete
    true


  end


  def create_hash

    connection = create_connect('multichainrpc','aGdvLSLsnuSwP9t1RtVm8jCceyqeo3L4NTCH35f54DT')


    #client = create_client("http://localhost:7748",connection)

=begin
As of now we are just leaving the storage of the Hash inside the blockchain just creating the hash of the video file
=end

    sha256 = Digest::SHA256.file self.video_storageUrl

    hash = sha256.hexdigest

    update_column(:video_hash, hash)
    cache_delete
    true

  end

  def unique_hash(user_id,file)

    #Generates hash of the file
    file = File.open params[:file].tempfile

    sha256 = Digest::SHA256.file  file.to_path

    hash = sha256.hexdigest

    #Now retrieve all the hash values for User

    #videos = Video.find_by_user_id(user_id)

    #Now Iterate to match the hash



  end




  def get_labels

    #Make connections
    #Taking connection from the EXPORT GOOGLE APPLICATION AUTH

    video_client = Google::Cloud::VideoIntelligence::V1beta1::VideoIntelligenceServiceClient.new

    features     = [:LABEL_DETECTION]
    path = "gs://tidy-layout-9458/" + self.video_storageUrl
    #path = "gs://cloudmleap/video/next/animals.mp4"
    #path = "gs://tidy-layout-9458/4/78d202f34e6398a258fc672256b3db289b74c497c80b8f203b787643191ee21e/RackMultipart20170813-25827-1ciwdvw.mov"
    #path = "gs://tidy-layout-9458/4/b68218df6e69c7cc4e6d575794a48463df4aaaf3f4f7766d3ce61afb190a07a2/RackMultipart20170813-75579-11tqzs0.mp4"





    # Register a callback during the method call
    operation = video_client.annotate_video path, features do |operation|

      raise operation.results.message? if operation.results.nil?

      puts "Finished Processing."
      # first result is retrieved because a single video was processed
      annotation_result = operation.results.annotation_results.first
      labels = Hash.new{|hs,key| hs[key] = []}
      annotation_result.label_annotations.each do |label_annotation|

         puts "Label description: #{label_annotation.description}"
         "Locations:"

         #labels = labels + "," + label_annotation.description
         labels['labels'].push label_annotation.description

        label_annotation.locations.each do |location|
          if location.level == :VIDEO_LEVEL
             "Entire video"
          else
            segment          = location.segment
            start_in_seconds = segment.start_time_offset / 1000000.0
            end_in_seconds   = segment.end_time_offset / 1000000.0

             "#{start_in_seconds} through #{end_in_seconds}"
          end
        end
      end
      puts labels
      if labels.empty?
        update_column(:video_labels,labels.inspect)
        update_column(:proccesed, false)
        puts false
      else
        update_column(:video_labels, labels['labels'])
        update_column(:proccesed, true)
        cache_delete
        true
      end



      end

    puts "Processing video for label annotations:"
    operation.wait_until_done!
  end




  def get_speech_text

    #Extract Audio from The Video and Upload it to the GOOGLE CLOUD

    speech = Google::Cloud::Speech.new(
        project: "river-176215",
        keyfile: "config/google_settings.json"
    )

    audio_cloud_path = "gs://tidy-layout-9458/" + self.audio_url
    audio = speech.audio audio_cloud_path,
                         encoding: :FLAC,
                         language: "en-IN",
                         sample_rate: self.audio_sample_rate

    operation = audio.recognize_job

    puts "Operation Started"

    operation.done?


    operation.wait_until_done!


    operation.done?

    results = operation.results


    result = results.first

    puts "Transcription: #{result.transcript}"

    result.transcript
    result.confidence

    if result.transcript.empty?

      update_column(:speech, result.transcript)
      update_column(:audio_processed,false)
      cache_delete
    else
      update_column(:speech, result.transcript)
      update_column(:audio_processed,true)
      update_column(:audio_confidence, result.confidence)
      cache_delete
      true


    end


    language = Google::Cloud::Language.new

    content = self.speech

    document = language.document content

    annotation = document.annotate

    #For Now Get the Entity

    entities = annotation.entities

    entities_array = []

    entities.each do |k|
      entities_array << k.name
    end

    puts entities_array

    update_column(:audio_labels, entities_array)

    #Get The Scores
    sentiment_score = annotation.sentiment.score

    update_column(:sentiment_score, sentiment_score)
    cache_delete
    true



  end


  def process_video

    #Check Video is Processed and Then Send Notifications

    #Create a ticket from the user where a user can create a ticket and then send a notification

    #As of now just send the POST Request for the user using credentials

    @ticket = Ticket.new

    @ticket.title = 'Automated Video River Flow'
    @ticket.group = Group.find_by_name("Users")
    @ticket.customer_id = self.user_id
    @ticket.note = "Please confirm the customer about the ticket which he has created"
    @ticket.create_article_type = Ticket::Article::Type.find_by_name('web')
    @ticket.created_by_id = self.user_id
    @ticket.updated_by_id = self.user_id
    @ticket.save!

    #Now Create some Articles
    #Before doing things we need some vars
    user = User.find_by_id(self.user_id)
    from = user.firstname + " "  +  user.lastname + " " + "<" + user.email + ">"

    @articles = Ticket::Article.new
    @articles.ticket = @ticket
    @articles.type = Ticket::Article::Type.find_by_name('web')
    @articles.sender = Ticket::Article::Sender.find_by_name('customer')
    @articles.from = from
    @articles.to = 'Users'
    @articles.content_type = 'text/html'
    @articles.body = "Video Labels #{self.video_labels} <br> Audio Labels #{self.audio_labels} <br> Problem Text #{self.speech} <br> Audio Confidence #{self.audio_confidence}, <br> Sentiment Score #{self.sentiment_score} <br> Some Analytics Also #{self.analytics}"
    @articles.internal = false
    @articles.created_by = user
    @articles.updated_by = user
    @articles.origin_by_id = self.user_id
    @articles.save!







  end



  def get_ibm_labels

    #Get the reply for video content only for the customer from the admin or an agent


    url = URI("https://gateway.watsonplatform.net/natural-language-understanding/api/v1/analyze?version=2017-02-27")

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Post.new(url)
    request["authorization"] = 'Basic YjdjZGY3NjktOWEzOS00MGEyLTk2YWYtMjAwYmQwY2MxNDcxOmpFNEVJUGc4akYzNQ=='
    request["content-type"] = 'application/json'
    request["cache-control"] = 'no-cache'
    request["postman-token"] = '67fdc2e6-0e31-22af-35ce-ba144fb6f8e1'
    request.body = {:text=>self.speech, :features=>{:entities=>{}, :keywords=>{}, :concepts=>{}, :categories=>{}, :emotion=>{}, :relations=>{}}}.to_json
    response = http.request(request)
    puts response.read_body

    hash = JSON[response.read_body]

    update_column(:analytics,  hash)
    cache_delete
    true




  end



end
