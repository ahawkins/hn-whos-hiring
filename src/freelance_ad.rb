require 'htmlentities'

class FreelanceAd < JobAd
  def seeking_work?
    # Some ads do not mention either. They're likely seeking work
    if !text.include?('SEEKING WORK') && !text.include?('SEEKING FREELANCER')
      true
    else
      text.include?('SEEKING WORK')
    end
  end

  def remote?
    !!(text =~ /remote:\s(yes|ok)/i || text =~ /REMOTE/ || text =~ /Remote only/)
  end

  def title
    text.
      # NOTE: The .* matches any junk text that some people post to make
      # their post stand out
      gsub(/\A.*SEEKING (WORK|FREELANCERS?)/, '').
      gsub(/\A[^a-zA-Z<]*/, '').
      gsub(/\A<p>/, '').
      split('<p>').
      join('; ')
  end
end
