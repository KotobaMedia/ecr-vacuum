#!/usr/bin/env ruby

require_relative "./lib/setup"

DRY_RUN = !!ENV["DRY_RUN"]

region = ENV["AWS_REGION"] || "us-east-1"
ecr = Aws::ECR::Client.new(region: region)
repositories = ecr.describe_repositories({max_results: 100})

puts "Starting at #{Time.now.to_s}"

if DRY_RUN
  puts "[!!] Dry run mode enabled! Images will not be destroyed."
end

def tag_list_includes_tag?(image_tags, cmp_tag)
  image_tags.any? do |tag|
    tag == cmp_tag ||
    (cmp_tag.length >= 7 && tag[0..(cmp_tag.length - 1)] == cmp_tag)
  end
end

repositories.repositories.each do |repository|
  config = config_for(repository.repository_name)
  if !config
    puts "Repository #{repository.repository_name} not in config, skipping."
    next
  end

  puts "Repository #{repository.repository_name} starting."

  image_ids = []
  next_token = nil
  while true
    list_opts = {
      repository_name: repository.repository_name,
      max_results: 100
    }
    list_opts[:next_token] = next_token if next_token
    images = ecr.list_images(list_opts)
    image_ids += images.image_ids
    if !(next_token = images.next_token)
      break
    end
  end

  g = open_repository(repository.repository_name)
  valid_image_tags = config["keep_branches"].
    map do |branch|
      g.log(10).object(branch).map(&:sha)
    end.
    flatten.
    uniq

  images_to_destroy = image_ids.reduce([]) do |acc, image|
    if !tag_list_includes_tag?(valid_image_tags, image.image_tag)
      puts "==> \"#{image.image_tag}\" marked for destroy"
      acc << {
        image_tag: image.image_tag,
        image_digest: image.image_digest
      }
    else
      acc
    end
  end

  if !DRY_RUN && images_to_destroy.any?
    ecr.batch_delete_image({
      repository_name: repository.repository_name,
      image_ids: images_to_destroy
    })
  else
    puts "Found no images to destroy."
  end

  puts "Repository #{repository.repository_name} finished."
end
