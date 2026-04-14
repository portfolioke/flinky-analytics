{% %} # some sort of operation that happens inside the Jinja context. Invisible. 

{% set temperature = 80.0 %}

{% if temperature > 75.0 %}
    {% set state = 'hot' %}
{% if temperature < 60.0 %}
    {% set state = 'cold' %}
{% else %}
    {% set state = 'warm' %}




{{ }} # pulling out something of the Jinja context and printing it in the file we are interacting with. Written material.