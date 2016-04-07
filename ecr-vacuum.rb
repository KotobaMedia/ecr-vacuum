#!/usr/bin/env ruby

require_relative "./lib/setup"

region = ENV["AWS_REGION"] || "us-east-1"
ecr = Aws::ECR::Client.new(region: region)
repositories = ecr.describe_repositories({max_results: 100})

puts "Starting at #{Time.now.to_s}"

repositories.repositories.each do |repository|
  puts "Repository #{repository.repository_name} starting."

  images = ecr.list_images({
    repository_name: repository.repository_name,
    max_results: 100
  })

  config = config_for(repository.repository_name)

  g = open_repository(repository.repository_name)
  valid_image_tags = config["keep_branches"].
    map do |branch|
      g.log(10).object(branch).map(&:sha)
    end.
    flatten.
    uniq

  images_to_destroy = images.image_ids.reduce([]) do |acc, image|
    if !valid_image_tags.include?(image.image_tag)
      puts "==> \"#{image.image_tag}\" marked for destroy"
      acc << {
        image_tag: image.image_tag,
        image_digest: image.image_digest
      }
    else
      acc
    end
  end

  if images_to_destroy.any?
    ecr.batch_delete_image({
      repository_name: repository.repository_name,
      image_ids: images_to_destroy
    })
  else
    puts "Found no images to destroy."
  end

  puts "Repository #{repository.repository_name} finished."
end
