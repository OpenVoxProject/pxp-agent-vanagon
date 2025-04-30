namespace :vox do
  desc 'Upload artifacts from the output directory to S3. Requires the AWS CLI to be installed and configured appropriately.'
  task :upload, [:tag, :platform] do |_, args|
    endpoint = ENV.fetch('ENDPOINT_URL')
    bucket = ENV.fetch('BUCKET_NAME')
    component = 'pxp-agent'
    platform = args[:platform] || ''

    abort 'You must set the ENDPOINT_URL environment variable to the S3 server you want to upload to.' if endpoint.nil? || endpoint.empty?
    abort 'You must set the BUCKET_NAME environment variable to the S3 bucket you are uploading to.' if bucket.nil? || bucket.empty?
    abort 'You must provide a tag.' if args[:tag].nil? || args[:tag].empty?

    munged_tag = args[:tag].gsub('-', '.')
    s3 = "aws s3 --endpoint-url=#{endpoint}"

    # Ensure the AWS CLI isn't going to fail with the given parameters
    run_command("#{s3} ls s3://#{bucket}/")

    prepend = File.directory?('/cygdrive/') ? 'C:/cygwin64/' : ''
    files = Dir.glob("#{prepend}#{__dir__}/../output/*#{munged_tag}*#{platform}*")
    puts 'No files for the given tag found in the output directory.' if files.empty?

    path = "s3://#{bucket}/#{component}/#{args[:tag]}"
    files.each do |f|
      run_command("#{s3} cp #{f} #{path}/#{File.basename(f)} --endpoint-url=#{endpoint}", silent: false)
    end
  end
end
