## A short course on Mathematical Epidemiology

These are the slides and some code for a course taught during the 3MC workshop on Bioinformatics and Mathematical Modelling, held at Arba Minch University in December 2023.

On the [GitHub version](https://github.com/julien-arino/3MC-2023-12-Arba-Minch/) of the page, you have access to all the files. You can also download the entire repository by clicking the buttons on the left. (You can also of course clone this repo, but you will need to do that from the GitHub version of the site.)

Feel free to use the material in these slides or in the folders. If you find this useful, I will be happy to know.

### Slides

Please note that at present, the slides are work in progress. I will be updating them as the course progresses.

<ul>
{% for file in site.static_files %}
  {% if file.path contains 'SLIDES' %}
    {% if file.path contains 'course' %}
      {% if file.path contains 'pdf' %}
        {% unless file.path contains 'FIGS' %}
          <li><a href="https://julien-arino.github.io/3MC-2023-12-Arba-Minch/SLIDES/{{ file.basename }}.pdf">{{ file.basename }}</a></li>
        {% endunless %}
      {% endif %}
    {% endif %}
  {% endif %}
{% endfor %}
</ul>

At present, there are no videos of the lectures. I will be recording videos when time permits, probably in early 2024.