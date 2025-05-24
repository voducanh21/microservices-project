FROM eclipse-temurin:21-jdk

WORKDIR /app

COPY target/*.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]

# FROM alpine:3.6
  #
  #RUN apk add --no-cache openjdk8
  #
  #WORKDIR /app
  #
  #COPY target/*.jar app.jar
  #
  #EXPOSE 8080
  #
  #ENTRYPOINT ["java", "-jar", "app.jar"]