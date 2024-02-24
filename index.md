## African Mathematical School on Quantitative Biology: Applications in Epidemiology, Ecology and Cancer
 
Here are some slides and material for the [3MC African Mathematical School on Quantitative Biology: Applications in Epidemiology, Ecology and Cancer](https://natural-sciences.nwu.ac.za/paa/3MC-School-2024), held at Northwest University (Potchefstroom) in February 2024.

On the [GitHub version](https://github.com/julien-arino/3MC-2024-02-Potch/) of the page, you have access to all the files. You can also download the entire repository by clicking the buttons on the left. (You can also of course clone this repo, but you will need to do that from the GitHub version of the site.)

Feel free to use the material in these slides or in the folders. If you find this useful, we will be happy to know.

### Slides Inger

- [Spatial SEIR models](inger/SS.pdf)
- [Ordinary Kriging in QGIS and R](inger/RThiede_OrdinaryKriging.pdf)

Html produced from Rmarkdown files. You can find the Rmarkdown files in the `inger` directory.
<ul>
{% for file in site.static_files %}
  {% if file.path contains 'inger' %}
    {% if file.path contains 'html' %}
      <li><a href="https://julien-arino.github.io/3MC-2024-02-Potch/inger/{{ file.basename }}.html">{{ file.basename }}</a></li>
    {% endif %}
  {% endif %}
{% endfor %}
</ul>
- [Uncertainty and sensitivity analysis](inger/Lecture-2.pdf) by Dr Raeesa Manjoo-Docrat

### Slides Jacek

### Slides James

You can find James' slides on his [web page](https://jameswatmough.github.io/teaching/).

### Slides Julien

Please note that at present, the slides are work in progress. I will be updating them as the course progresses.

<ul>
{% for file in site.static_files %}
  {% if file.path contains 'julien' %}
    {% if file.path contains 'SLIDES' %}
      {% if file.path contains 'course' %}
        {% if file.path contains 'pdf' %}
          {% unless file.path contains 'FIGS' %}
            <li><a href="https://julien-arino.github.io/3MC-2024-02-Potch/julien/SLIDES/{{ file.basename }}.pdf">{{ file.basename }}</a></li>
          {% endunless %}
        {% endif %}
      {% endif %}
    {% endif %}
  {% endif %}
{% endfor %}
</ul>

I have some "vignettes" about `R` [here](https://julien-arino.github.io/R-for-modellers/). Beware, some of them are not finished yet.

### Slides Patrick

See the slides [here](assets/pdf/3MC_school_2024_Patrick.pdf).

### Slides Stéphanie

1. [Introduction to modelling](assets/pdf/Portet_2024_1_2.pdf)
2. [Beyond mathematical analysis](assets/pdf/Portet_2024_3.pdf)

