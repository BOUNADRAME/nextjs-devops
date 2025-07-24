docker build -t bootcamp-ui:1.0.0 .

# Build avec timing détaillé

time docker build -t bootcamp-ui:1.0.0 .

# Build avec progress détaillé

docker build --progress=plain -t bootcamp-ui:1.0.0 .

# Build sans cache pour tester la vitesse réelle

docker build --no-cache -t bootcamp-ui:1.0.0 .
