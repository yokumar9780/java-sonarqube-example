## How to Set Up on a Local Machine

1. **Create a Java project using Spring Initializr:**  
   Visit [https://start.spring.io/](https://start.spring.io/) to generate a new Spring Boot project.
2. **Add the following Sonar profile to your `pom.xml`:**

```xml

<profile>
    <!-- Usages: -->
    <!-- mvn clean install sonar:sonar -Dsonar.token=squ_e13a1c87e24cbdc34877e0b3331119437f04b6bb -->
    <id>sonar</id>
    <activation>
        <activeByDefault>true</activeByDefault>
    </activation>
    <properties>
        <!-- URL to the Sonar server -->
        <sonar.host.url>http://localhost:9000</sonar.host.url>
        <sonar.projectKey>java-example</sonar.projectKey>
        <sonar.projectName>java-example</sonar.projectName>
        <sonar.coverage.jacoco.xmlReportPaths>${project.build.directory}/**/*/jacoco.xml
        </sonar.coverage.jacoco.xmlReportPaths>
    </properties>
    <build>
        <plugins>
            <plugin>
                <groupId>org.sonarsource.scanner.maven</groupId>
                <artifactId>sonar-maven-plugin</artifactId>
                <version>5.1.0.4751</version>
            </plugin>
        </plugins>
    </build>
</profile>
```

3. Add other Maven plugins such as JaCoCo to provide additional metrics to the SonarQube server.
3. Run Docker Compose using the provided file: [docker compose](devops/docker-compose/docker-compose.yml)
4. Generate the SonarQube token using the auto-generation
   script: [Auto Generte bash file](devops/scripts/generate_sonarqube_token.sh)
5. Run the following command to send analysis data to the SonarQube server:

```bash
   mvn clean install sonar:sonar -Dsonar.token=squ_aa0f1ee4f6131d3988b6f219aa99662768bb6b99 
```

6. Login to the SonarQube server: [http://localhost:9000](http://localhost:9000)  The default credentials are:
   `admin` / `admin`. And view the auto-generated token under: **User Profile → Security**

## How to Set Up on a AWS EC2 instance using Terraform

[How to Set Up on a AWS EC2 instance using Terraform](devops/terraform-aws-ec2/terraform-ec2-project-readme.md)
